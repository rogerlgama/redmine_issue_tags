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
