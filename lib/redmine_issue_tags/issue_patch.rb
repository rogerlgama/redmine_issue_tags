module RedmineIssueTags
  module IssuePatch
    extend ActiveSupport::Concern

    included do
      has_many :issue_taggings,
               class_name: 'RedmineIssueTagging',
               dependent: :delete_all,
               inverse_of: :issue
      has_many :issue_tags,
               through: :issue_taggings,
               source: :tag
    end

    def issue_tags_as_string
      RedmineIssueTags.tags_for(self)
                      .order(Arel.sql('LOWER(redmine_issue_tags.name) ASC'))
                      .pluck(:name)
                      .join(', ')
    end
  end
end
