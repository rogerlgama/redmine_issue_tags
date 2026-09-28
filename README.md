# Redmine Issue Tags

Searchable issue tags for Redmine, with tracker restrictions, role-based permissions, issue filtering, grouping, history, and JSON API support.

Portuguese documentation: [README.pt-BR.md](README.pt-BR.md)

## Features

- Global administrative tag catalog with name, description, color, and allowed trackers.
- Independent checkbox selection for assigning multiple tags to an issue.
- Clickable colored tag badges on issue pages and in the administration list.
- Tag descriptions displayed as tooltips.
- Issue-query filter, optional column, CSV output, saved queries, and grouping by tag.
- Structured issue history for tag additions and removals.
- Role permissions for assigning existing tags and collaboratively creating or editing tags.
- Searchable role and tracker selectors without external JavaScript dependencies.
- Administrative JSON API for tags, linked issues, and role permissions.
- Automatic `issue_tags` data in Redmine's standard issue JSON API.
- Compatibility handling for MySQL, PostgreSQL, and SQLite.

The plugin does not modify Redmine core files.

## Requirements

- Redmine 6.0 or newer
- Ruby and Rails versions supported by the installed Redmine version
- A database supported by Redmine

The plugin was developed and validated for Redmine 6.0.6.

## Installation

1. Back up the Redmine database and files.
2. Copy the plugin to `REDMINE_ROOT/plugins/redmine_issue_tags`.
3. From the Redmine root, run:

   ```bash
   bundle exec rake redmine:plugins:migrate NAME=redmine_issue_tags RAILS_ENV=production
   ```

4. Restart Redmine.
5. Open **Administration → Roles and permissions** and enable the required tag permissions.
6. Administrators can manage the tag catalog under **Administration → Tags**.

## Upgrade

1. Back up the database and the existing plugin directory.
2. Replace the plugin files, keeping the directory name `redmine_issue_tags`.
3. Run the migration command shown above.
4. Restart Redmine.

Version 0.5.2 does not add a new migration. Installations upgrading from versions older than 0.4.11 must still run all pending plugin migrations.

## Permissions

- **Add and remove issue tags** allows users to assign existing tags to issues.
- **Create and edit tags directly in issues** allows collaborative creation and editing of tag name, description, and color.
- Tracker associations, deletion, and the global catalog remain restricted to administrators.

The global role selectors under **Administration → Tags → Roles** are synchronized with Redmine's native **Roles and permissions** screen.

## Standard Redmine API

The standard issue endpoints automatically include an `issue_tags` array. No `include` parameter is required:

```text
GET /issues/:id.json
GET /issues.json
```

Example:

```json
{
  "issue_tags": [
    {
      "id": 5,
      "name": "Security",
      "description": "Security-related work",
      "color": "#3b82f6"
    }
  ]
}
```

Issues without tags return an empty `issue_tags` array.

## Plugin API

The administrative endpoints require an administrator API key:

```text
GET /api/issue_tags/tags.json
GET /api/issue_tags/tags/:id.json
GET /api/issue_tags/tags/:id/issues.json
GET /api/issue_tags/issues/:issue_id/tags.json
GET /api/issue_tags/roles.json
```

The linked-issues endpoint supports `limit` and `offset`:

```text
GET /api/issue_tags/tags/5/issues.json?limit=100&offset=0
```

Issue assignment endpoints use Redmine's normal authentication and project permissions:

```text
GET /issues/:issue_id/tags.json
PUT /issues/:issue_id/tags.json
```

Example request body for replacing all tags assigned to an issue:

```json
{
  "tags": {
    "ids": [1, 2, 5]
  }
}
```

API authentication can use Redmine's standard `X-Redmine-API-Key` header.

## Tests

Run from the Redmine root:

```bash
bundle exec rails test plugins/redmine_issue_tags/test RAILS_ENV=test
```

## Uninstall

Roll back the plugin migrations before removing its directory:

```bash
bundle exec rake redmine:plugins:migrate NAME=redmine_issue_tags VERSION=0 RAILS_ENV=production
```

Then remove `plugins/redmine_issue_tags` and restart Redmine.

## Changelog

See [CHANGELOG.md](CHANGELOG.md). The detailed development history is currently maintained in Portuguese.

## License

Copyright holders license this project under the GNU General Public License version 2 or, at your option, any later version (`GPL-2.0-or-later`). See [LICENSE](LICENSE).

## Author

[Roger Gama](https://github.com/rogerlgama/redmine_issue_tags)
