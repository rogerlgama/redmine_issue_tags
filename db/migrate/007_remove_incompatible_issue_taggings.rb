class RemoveIncompatibleIssueTaggings < ActiveRecord::Migration[6.1]
  def up
    execute <<~SQL.squish
      DELETE FROM redmine_issue_taggings
      WHERE NOT EXISTS (
        SELECT 1
        FROM issues
        INNER JOIN redmine_issue_tag_trackers
          ON redmine_issue_tag_trackers.tracker_id = issues.tracker_id
         AND redmine_issue_tag_trackers.issue_tag_id = redmine_issue_taggings.issue_tag_id
        WHERE issues.id = redmine_issue_taggings.issue_id
      )
    SQL
  end

  def down
    # Os vínculos removidos eram incompatíveis e não devem ser restaurados.
  end
end
