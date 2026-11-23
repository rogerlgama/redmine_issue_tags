module RedmineIssueTags
  module IssuePatch
    extend ActiveSupport::Concern

    included do
      attr_accessor :redmine_issue_tags_pending_change

      has_many :issue_taggings,
               class_name: 'RedmineIssueTagging',
               dependent: :delete_all,
               inverse_of: :issue
      has_many :issue_tags,
               through: :issue_taggings,
               source: :tag

      after_save :redmine_issue_tags_apply_pending_change
    end

    def issue_tags_as_string
      RedmineIssueTags.tags_for(self)
                      .order(Arel.sql('LOWER(redmine_issue_tags.name) ASC'))
                      .pluck(:name)
                      .join(', ')
    end

    private

    def redmine_issue_tags_apply_pending_change
      change = redmine_issue_tags_pending_change
      return unless change

      RedmineIssueTags.persist_issue_tag_ids!(self, change[:author_id], change[:tag_ids])
    ensure
      self.redmine_issue_tags_pending_change = nil
    end
  end
end
