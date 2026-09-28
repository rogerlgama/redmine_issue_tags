class CreateRedmineIssueTagTrackers < ActiveRecord::Migration[6.1]
  def up
    create_table :redmine_issue_tag_trackers, id: false do |t|
      t.integer :issue_tag_id, null: false
      t.integer :tracker_id, null: false
    end

    add_index :redmine_issue_tag_trackers,
              [:issue_tag_id, :tracker_id],
              unique: true,
              name: 'idx_ritt_tag_tracker_unique'
    add_index :redmine_issue_tag_trackers,
              [:tracker_id, :issue_tag_id],
              name: 'idx_ritt_tracker_tag'

    tag_ids = select_values('SELECT id FROM redmine_issue_tags')
    tracker_ids = select_values('SELECT id FROM trackers')
    tag_ids.product(tracker_ids).each do |tag_id, tracker_id|
      execute <<~SQL.squish
        INSERT INTO redmine_issue_tag_trackers (issue_tag_id, tracker_id)
        VALUES (#{connection.quote(tag_id)}, #{connection.quote(tracker_id)})
      SQL
    end

    remove_column :redmine_issue_tags, :active, :boolean
  end

  def down
    add_column :redmine_issue_tags, :active, :boolean, null: false, default: true
    drop_table :redmine_issue_tag_trackers
  end
end
