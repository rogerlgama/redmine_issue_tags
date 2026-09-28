class ResetCollaborativeIssueTagRoles < ActiveRecord::Migration[6.1]
  def up
    execute 'DELETE FROM redmine_issue_tag_roles'
  end

  def down
    role_ids = select_values('SELECT id FROM roles WHERE builtin = 0')
    role_ids.each do |role_id|
      execute <<~SQL.squish
        INSERT INTO redmine_issue_tag_roles (role_id)
        VALUES (#{connection.quote(role_id)})
      SQL
    end
  end
end
