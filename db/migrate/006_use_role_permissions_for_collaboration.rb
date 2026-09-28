class UseRolePermissionsForCollaboration < ActiveRecord::Migration[6.1]
  PERMISSION = :collaborate_issue_tags

  def up
    selected_role_ids = select_values('SELECT role_id FROM redmine_issue_tag_roles').map(&:to_i)

    Role.givable.find_each do |role|
      permissions = Array(role.permissions).map(&:to_sym)
      permissions = if selected_role_ids.include?(role.id)
                      permissions | [PERMISSION]
                    else
                      permissions - [PERMISSION]
                    end
      role.update!(permissions: permissions)
    end

    drop_table :redmine_issue_tag_roles
  end

  def down
    create_table :redmine_issue_tag_roles, id: false do |t|
      t.integer :role_id, null: false
    end
    add_index :redmine_issue_tag_roles, :role_id, unique: true, name: 'idx_ritr_role_unique'

    Role.givable.find_each do |role|
      next unless Array(role.permissions).map(&:to_sym).include?(PERMISSION)

      execute <<~SQL.squish
        INSERT INTO redmine_issue_tag_roles (role_id)
        VALUES (#{connection.quote(role.id)})
      SQL
    end
  end
end
