require_dependency File.expand_path('../app/models/redmine_issue_tag', __dir__)
require_dependency File.expand_path('../app/models/redmine_issue_tagging', __dir__)
require_dependency 'issue'
require_dependency 'issue_query'
require 'redmine/views/builders/json'

require_relative 'redmine_issue_tags/hooks'
require_relative 'redmine_issue_tags/issue_patch'
require_relative 'redmine_issue_tags/issue_query_patch'
require_relative 'redmine_issue_tags/json_builder_patch'

module RedmineIssueTags
  TAG_CHANGE_OPERATIONS = %w[add remove replace].freeze

  def self.database_ready?
    RedmineIssueTag.table_exists? &&
      RedmineIssueTagging.table_exists? &&
      ActiveRecord::Base.connection.data_source_exists?('redmine_issue_tag_trackers')
  rescue ActiveRecord::NoDatabaseError, ActiveRecord::StatementInvalid, NameError
    false
  end

  def self.tags_for(issue)
    return RedmineIssueTag.none unless database_ready? && issue&.persisted?

    tag_ids = RedmineIssueTagging.where(issue_id: issue.id).select(:issue_tag_id)
    RedmineIssueTag.where(id: tag_ids)
  end

  def self.tag_ids_for(issue)
    return [] unless database_ready? && issue&.persisted?

    RedmineIssueTagging.where(issue_id: issue.id).pluck(:issue_tag_id)
  end

  def self.available_tags_for_issues(issues, target_tracker_id: nil)
    return RedmineIssueTag.none unless database_ready?

    tracker_ids = if target_tracker_id.present?
                    [target_tracker_id.to_i]
                  else
                    Array(issues).filter_map(&:tracker_id).map(&:to_i).uniq
                  end
    return RedmineIssueTag.none if tracker_ids.empty?

    tag_ids = RedmineIssueTag
              .active
              .joins(:trackers)
              .where(trackers: {id: tracker_ids})
              .group("#{RedmineIssueTag.table_name}.id")
              .having('COUNT(DISTINCT trackers.id) = ?', tracker_ids.size)
              .pluck("#{RedmineIssueTag.table_name}.id")

    RedmineIssueTag.active.where(id: tag_ids).sorted
  end

  def self.issue_tag_change_plan(issue, requested_ids, operation:)
    return unless database_ready? && issue&.persisted?

    operation = operation.to_s
    return unless TAG_CHANGE_OPERATIONS.include?(operation)

    requested_ids = Array(requested_ids).map(&:to_i).select(&:positive?).uniq
    old_ids = tag_ids_for(issue).map(&:to_i).uniq.sort
    compatible_ids = compatible_tag_ids(issue.tracker_id, requested_ids)

    new_ids =
      case operation
      when 'add'
        (old_ids | compatible_ids).sort
      when 'remove'
        (old_ids - requested_ids).sort
      when 'replace'
        compatible_ids.sort
      end

    return if old_ids == new_ids

    {
      old_ids: old_ids,
      new_ids: new_ids,
      old_names: tag_names_for_ids(old_ids),
      new_names: tag_names_for_ids(new_ids)
    }
  end

  def self.change_issue_tags!(issue, user, requested_ids, operation: :replace)
    return false unless can_assign_tags?(user, issue&.project)

    change = issue_tag_change_plan(issue, requested_ids, operation: operation)
    return false unless change

    persist_issue_tag_ids!(issue, user, change[:new_ids])
    record_tag_change(issue, user, change[:old_names], change[:new_names])
    true
  end

  def self.queue_issue_tag_change!(issue, user, requested_ids, operation:)
    return false unless can_assign_tags?(user, issue&.project)

    change = issue_tag_change_plan(issue, requested_ids, operation: operation)
    return false unless change

    journal = issue.current_journal || issue.init_journal(user)
    journal.details.build(
      property: 'attr',
      prop_key: 'issue_tags',
      old_value: change[:old_names].join(', ').presence,
      value: change[:new_names].join(', ').presence
    )
    issue.redmine_issue_tags_pending_change = {
      tag_ids: change[:new_ids],
      author_id: user.id
    }
    true
  end

  def self.persist_issue_tag_ids!(issue, user_or_id, tag_ids)
    desired_ids = Array(tag_ids).map(&:to_i).select(&:positive?).uniq
    author_id = user_or_id.respond_to?(:id) ? user_or_id.id : user_or_id

    RedmineIssueTagging.transaction do
      RedmineIssueTagging.where(issue_id: issue.id).where.not(issue_tag_id: desired_ids).delete_all
      existing_ids = RedmineIssueTagging.where(issue_id: issue.id, issue_tag_id: desired_ids).pluck(:issue_tag_id)
      (desired_ids - existing_ids).each do |tag_id|
        RedmineIssueTagging.create!(issue_id: issue.id, issue_tag_id: tag_id, author_id: author_id)
      end
    end
  end

  def self.inject_tags_into_standard_api!(payload, route_parameters)
    return payload unless database_ready? && payload.is_a?(Hash)

    controller = route_parameters[:controller] || route_parameters['controller']
    action = route_parameters[:action] || route_parameters['action']
    return payload unless controller.to_s == 'issues'

    issue_nodes =
      case action.to_s
      when 'show'
        issue = payload[:issue] || payload['issue']
        issue.is_a?(Hash) ? [issue] : []
      when 'index'
        issues = payload[:issues] || payload['issues']
        issues.is_a?(Array) ? issues.select {|issue| issue.is_a?(Hash)} : []
      else
        []
      end

    issue_ids = issue_nodes.filter_map {|issue| issue[:id] || issue['id']}.map(&:to_i).select(&:positive?).uniq
    return payload if issue_ids.empty?

    tags_by_issue_id = Hash.new {|hash, issue_id| hash[issue_id] = []}
    RedmineIssueTagging
      .joins(:tag)
      .where(issue_id: issue_ids)
      .order(Arel.sql('redmine_issue_taggings.issue_id ASC, LOWER(redmine_issue_tags.name) ASC'))
      .pluck(
        :issue_id,
        'redmine_issue_tags.id',
        'redmine_issue_tags.name',
        'redmine_issue_tags.description',
        'redmine_issue_tags.color'
      ).each do |issue_id, tag_id, name, description, color|
        tags_by_issue_id[issue_id] << {
          id: tag_id,
          name: name,
          description: description,
          color: color
        }
      end

    issue_nodes.each do |issue|
      issue_id = (issue[:id] || issue['id']).to_i
      issue[:issue_tags] = tags_by_issue_id.fetch(issue_id, [])
    end

    payload
  end

  def self.can_assign_tags?(user, project)
    user.admin? ||
      user.allowed_to?(:edit_issue_tags, project) ||
      user.allowed_to?(:collaborate_issue_tags, project)
  end

  def self.can_collaborate_tags?(user, project)
    user.admin? || user.allowed_to?(:collaborate_issue_tags, project)
  end

  def self.compatible_tag_ids(tracker_id, tag_ids)
    ids = Array(tag_ids).map(&:to_i).select(&:positive?).uniq
    return [] if tracker_id.blank? || ids.empty?

    RedmineIssueTag
      .active
      .joins(:trackers)
      .where(id: ids, trackers: {id: tracker_id})
      .distinct
      .pluck("#{RedmineIssueTag.table_name}.id")
  end

  def self.tag_names_for_ids(tag_ids)
    ids = Array(tag_ids).map(&:to_i).select(&:positive?).uniq
    return [] if ids.empty?

    RedmineIssueTag
      .where(id: ids)
      .reorder(Arel.sql('LOWER(redmine_issue_tags.name) ASC'))
      .pluck(:name)
  end

  def self.record_tag_change(issue, user, old_names, new_names)
    return if old_names == new_names

    old_value = old_names.join(', ').presence
    new_value = new_names.join(', ').presence
    journal = issue.respond_to?(:current_journal) ? issue.current_journal : nil

    Journal.transaction do
      # Na criação ou em uma edição comum, reutiliza o diário que o Redmine
      # acabou de persistir. Em alterações exclusivas de tags (como na API),
      # cria um diário próprio, sem transformar a mudança em uma nota.
      journal = Journal.create!(journalized: issue, user: user) unless journal&.persisted?
      journal.details.create!(
        property: 'attr',
        prop_key: 'issue_tags',
        old_value: old_value,
        value: new_value
      )
    end
  end

  def self.tags_grouping_sql
    issue_id = "#{Issue.table_name}.id"
    taggings = RedmineIssueTagging.table_name
    tags = RedmineIssueTag.table_name

    case ActiveRecord::Base.connection.adapter_name.downcase
    when /mysql/
      "(SELECT GROUP_CONCAT(rit.name ORDER BY LOWER(rit.name) SEPARATOR ', ') " \
        "FROM #{taggings} rig " \
        "INNER JOIN #{tags} rit ON rit.id = rig.issue_tag_id " \
        "WHERE rig.issue_id = #{issue_id})"
    when /postgres/
      "(SELECT STRING_AGG(rit.name, ', ' ORDER BY LOWER(rit.name)) " \
        "FROM #{taggings} rig " \
        "INNER JOIN #{tags} rit ON rit.id = rig.issue_tag_id " \
        "WHERE rig.issue_id = #{issue_id})"
    else
      "(SELECT GROUP_CONCAT(rit.name, ', ') FROM #{taggings} rig " \
        "INNER JOIN #{tags} rit ON rit.id = rig.issue_tag_id " \
        "WHERE rig.issue_id = #{issue_id})"
    end
  end

  def self.apply_patches!
    Issue.include(IssuePatch) unless Issue.included_modules.include?(IssuePatch)
    IssueQuery.prepend(IssueQueryPatch) unless IssueQuery.ancestors.include?(IssueQueryPatch)
    json_builder = Redmine::Views::Builders::Json
    json_builder.prepend(JsonBuilderPatch) unless json_builder.ancestors.include?(JsonBuilderPatch)

    if database_ready? && !IssueQuery.available_columns.any? { |column| column.name == :issue_tags_as_string }
      grouping_sql = tags_grouping_sql
      IssueQuery.available_columns << IssueTagsQueryColumn.new(
        :issue_tags_as_string,
        caption: :field_issue_tags,
        sortable: grouping_sql,
        groupable: true,
        group_by_statement: "#{Issue.table_name}.id"
      )
    end
  end
end

Rails.configuration.to_prepare do
  RedmineIssueTags.apply_patches!
end

# Em produção, o arquivo do plugin pode ser carregado depois da execução dos
# callbacks de preparação. A aplicação imediata garante o patch no primeiro boot.
RedmineIssueTags.apply_patches!
