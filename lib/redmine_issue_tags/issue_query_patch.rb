module RedmineIssueTags
  class IssueTagsQueryColumn < QueryColumn
    def initialize(name, options={})
      options = options.dup
      @issue_tags_group_by_statement = options.delete(:group_by_statement)
      super(name, options)
    end

    def group_by_statement
      @issue_tags_group_by_statement
    end

    def group_value(object)
      if object.instance_variable_defined?(:@redmine_issue_tag_group_name)
        object.instance_variable_get(:@redmine_issue_tag_group_name)
      else
        super
      end
    end
  end

  module IssueQueryPatch
    def issues(options={})
      issues = super
      return issues unless issue_tags_grouped?

      issues_by_tag = Hash.new {|hash, tag_name| hash[tag_name] = []}

      issues.each do |issue|
        issue_tag_names_by_issue.fetch(issue.id, ['']).each do |tag_name|
          grouped_issue = issue.clone
          grouped_issue.instance_variable_set(:@redmine_issue_tag_group_name, tag_name)
          issues_by_tag[tag_name] << grouped_issue
        end
      end

      group_names = issues_by_tag.keys.sort_by {|name| name.to_s.downcase}
      group_names.reverse! if issue_tags_group_order == 'desc'
      group_names.flat_map {|tag_name| issues_by_tag[tag_name]}
    end

    def result_count_by_group
      return super unless issue_tags_grouped?

      issue_tag_grouped_issue_ids.transform_values(&:size)
    end

    def total_by_group_for(column)
      return super unless issue_tags_grouped?

      issue_tag_grouped_issue_ids.each_with_object({}) do |(group_name, issue_ids), totals|
        scope = base_scope.where(issues: {id: issue_ids})
        totals[group_name] = send(:total_with_scope, column, scope)
      end
    end

    def initialize_available_filters
      super
      return unless RedmineIssueTags.database_ready?

      add_available_filter(
        'issue_tags',
        type: :list_optional,
        name: l(:field_issue_tags),
        values: lambda { RedmineIssueTag.active.sorted.map { |tag| [tag.name, tag.id.to_s] } }
      )
    end

    def sql_for_issue_tags_field(field, operator, values)
      return '1=0' unless RedmineIssueTags.database_ready?

      ids = Array(values).map(&:to_i).select(&:positive?)
      table = RedmineIssueTagging.table_name
      issue_id = "#{Issue.table_name}.id"
      exists_any = "EXISTS (SELECT 1 FROM #{table} rit WHERE rit.issue_id = #{issue_id})"

      case operator
      when '*'
        exists_any
      when '!*'
        "NOT #{exists_any}"
      when '='
        return '1=0' if ids.empty?
        "EXISTS (SELECT 1 FROM #{table} rit WHERE rit.issue_id = #{issue_id} AND rit.issue_tag_id IN (#{ids.join(',')}))"
      when '!'
        return '1=1' if ids.empty?
        "NOT EXISTS (SELECT 1 FROM #{table} rit WHERE rit.issue_id = #{issue_id} AND rit.issue_tag_id IN (#{ids.join(',')}))"
      else
        '1=0'
      end
    end

    private

    def issue_tags_grouped?
      group_by_column.is_a?(RedmineIssueTags::IssueTagsQueryColumn)
    end

    def issue_tag_grouped_issue_ids
      return @issue_tag_grouped_issue_ids if defined?(@issue_tag_grouped_issue_ids)

      groups = Hash.new {|hash, tag_name| hash[tag_name] = []}
      issue_tag_names_by_issue.each do |issue_id, tag_names|
        tag_names.each {|tag_name| groups[tag_name] << issue_id}
      end

      @issue_tag_grouped_issue_ids = groups
    end

    def issue_tag_names_by_issue
      return @issue_tag_names_by_issue if defined?(@issue_tag_names_by_issue)

      # O PostgreSQL exige que toda expressão de ORDER BY também esteja no
      # SELECT quando DISTINCT é usado. A ordenação da consulta principal não
      # interfere nesta coleta de IDs e deve ser removida antes do pluck.
      issue_ids = base_scope.reorder(nil).distinct.pluck("#{Issue.table_name}.id")
      names_by_issue = Hash.new {|hash, issue_id| hash[issue_id] = []}

      if issue_ids.any?
        taggings = RedmineIssueTagging
          .joins(:tag)
          .where(issue_id: issue_ids)

        selected_tag_ids = issue_tags_grouping_filter_ids
        taggings = taggings.where(issue_tag_id: selected_tag_ids) unless selected_tag_ids.nil?

        taggings
          .order(Arel.sql('LOWER(redmine_issue_tags.name) ASC'))
          .pluck(:issue_id, 'redmine_issue_tags.name')
          .each {|issue_id, name| names_by_issue[issue_id] << name}
      end

      issue_ids.each do |issue_id|
        names_by_issue[issue_id] = [''] if names_by_issue[issue_id].empty?
      end

      @issue_tag_names_by_issue = names_by_issue
    end

    def issue_tags_group_order
      sort_criteria.order_for(group_by_column.name).to_s.downcase
    rescue NoMethodError
      group_by_column.default_order.to_s.downcase
    end

    def issue_tags_grouping_filter_ids
      tag_filter = filters['issue_tags'] || filters[:issue_tags]
      return nil unless tag_filter

      operator = tag_filter['operator'] || tag_filter[:operator]
      return nil unless operator == '='

      values = tag_filter['values'] || tag_filter[:values]
      Array(values).map(&:to_i).select(&:positive?)
    end
  end
end
