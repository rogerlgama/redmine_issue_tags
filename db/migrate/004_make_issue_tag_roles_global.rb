class MakeIssueTagRolesGlobal < ActiveRecord::Migration[6.1]
  def up
    role_ids = select_values('SELECT DISTINCT role_id FROM redmine_issue_tag_roles')

    drop_table :redmine_issue_tag_roles
    create_table :redmine_issue_tag_roles, id: false do |t|
      t.integer :role_id, null: false
    end
    add_index :redmine_issue_tag_roles, :role_id, unique: true, name: 'idx_ritr_role_unique'

    role_ids.each do |role_id|
      execute <<~SQL.squish
        INSERT INTO redmine_issue_tag_roles (role_id)
        VALUES (#{connection.quote(role_id)})
      SQL
    end
  end

  def down
    role_ids = select_values('SELECT role_id FROM redmine_issue_tag_roles')

    drop_table :redmine_issue_tag_roles
    create_table :redmine_issue_tag_roles, id: false do |t|
      t.integer :issue_tag_id, null: false
      t.integer :role_id, null: false
    end
    add_index :redmine_issue_tag_roles,
              [:issue_tag_id, :role_id],
              unique: true,
              name: 'idx_ritr_tag_role_unique'
    add_index :redmine_issue_tag_roles,
              [:role_id, :issue_tag_id],
              name: 'idx_ritr_role_tag'

    tag_ids = select_values('SELECT id FROM redmine_issue_tags')
    tag_ids.product(role_ids).each do |tag_id, role_id|
      execute <<~SQL.squish
        INSERT INTO redmine_issue_tag_roles (issue_tag_id, role_id)
        VALUES (#{connection.quote(tag_id)}, #{connection.quote(role_id)})
      SQL
    end
  end
end
