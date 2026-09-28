class CreateRedmineIssueTags < ActiveRecord::Migration[6.1]
  def change
    create_table :redmine_issue_tags do |t|
      t.string :name, null: false, limit: 80
      t.string :normalized_name, null: false, limit: 80
      t.string :color, null: false, limit: 7, default: '#3b82f6'
      t.text :description
      t.boolean :active, null: false, default: true
      t.timestamps null: false
    end
    add_index :redmine_issue_tags, :normalized_name, unique: true

    create_table :redmine_issue_taggings do |t|
      t.integer :issue_id, null: false
      t.integer :issue_tag_id, null: false
      t.integer :author_id
      t.datetime :created_at, null: false
    end
    add_index :redmine_issue_taggings, [:issue_id, :issue_tag_id], unique: true, name: 'idx_rit_issue_tag_unique'
    add_index :redmine_issue_taggings, [:issue_tag_id, :issue_id], name: 'idx_rit_tag_issue'
    add_index :redmine_issue_taggings, :author_id
  end
end

