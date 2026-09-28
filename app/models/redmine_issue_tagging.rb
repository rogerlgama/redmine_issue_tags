class RedmineIssueTagging < ActiveRecord::Base
  self.table_name = 'redmine_issue_taggings'

  belongs_to :issue, inverse_of: :issue_taggings
  belongs_to :tag,
             class_name: 'RedmineIssueTag',
             foreign_key: :issue_tag_id,
             inverse_of: :taggings
  belongs_to :author,
             class_name: 'User',
             optional: true

  validates :issue_id, uniqueness: {scope: :issue_tag_id}
end

