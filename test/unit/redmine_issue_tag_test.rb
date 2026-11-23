require File.expand_path('../test_helper', __dir__)

class RedmineIssueTagTest < ActiveSupport::TestCase
  test 'normalizes name and applies default color' do
    tag = RedmineIssueTag.create!(name: '  Produção  ', color: '', trackers: [Tracker.first])
    assert_equal 'Produção', tag.name
    assert_equal 'produção', tag.normalized_name
    assert_equal '#3b82f6', tag.color
  end

  test 'does not allow duplicate normalized names' do
    RedmineIssueTag.create!(name: 'Urgente', trackers: [Tracker.first])
    duplicate = RedmineIssueTag.new(name: ' urgente ', trackers: [Tracker.first])
    assert_not duplicate.valid?
  end

  test 'adds tags to the standard issue api payload' do
    issue = Issue.first
    tag = RedmineIssueTag.create!(name: 'API padrão', description: 'Visível na tarefa', color: '#123456', trackers: [issue.tracker])
    RedmineIssueTagging.create!(issue: issue, tag: tag, author: User.first)
    payload = {issue: {id: issue.id, subject: issue.subject}}

    RedmineIssueTags.inject_tags_into_standard_api!(payload, controller: 'issues', action: 'show')

    assert_equal [
      {
        id: tag.id,
        name: 'API padrão',
        description: 'Visível na tarefa',
        color: '#123456'
      }
    ], payload.dig(:issue, :issue_tags)
  end

  test 'adds an empty tag list to untagged issues in the standard api payload' do
    issue = Issue.where.not(id: RedmineIssueTagging.select(:issue_id)).first || Issue.first
    RedmineIssueTagging.where(issue_id: issue.id).delete_all
    payload = {issues: [{id: issue.id, subject: issue.subject}]}

    RedmineIssueTags.inject_tags_into_standard_api!(payload, controller: 'issues', action: 'index')

    assert_equal [], payload.dig(:issues, 0, :issue_tags)
  end

  test 'adds a tag without removing the existing assignments' do
    issue = Issue.first
    user = User.find(1)
    existing_tag = RedmineIssueTag.create!(name: 'Tag existente', trackers: [issue.tracker])
    added_tag = RedmineIssueTag.create!(name: 'Tag adicionada', trackers: [issue.tracker])
    RedmineIssueTagging.create!(issue: issue, tag: existing_tag, author: user)

    changed = RedmineIssueTags.change_issue_tags!(issue, user, [added_tag.id], operation: :add)

    assert changed
    assert_equal [existing_tag.id, added_tag.id].sort, RedmineIssueTags.tag_ids_for(issue).sort
  end

  test 'queues a bulk tag change in the issue journal' do
    issue = Issue.first
    user = User.find(1)
    tag = RedmineIssueTag.create!(name: 'Tag em massa', trackers: [issue.tracker])
    issue.init_journal(user)

    queued = RedmineIssueTags.queue_issue_tag_change!(issue, user, [tag.id], operation: :add)
    issue.save!

    assert queued
    assert_equal [tag.id], RedmineIssueTags.tag_ids_for(issue)
    detail = issue.current_journal.details.detect {|item| item.prop_key == 'issue_tags'}
    assert_not_nil detail
    assert_nil detail.old_value
    assert_equal tag.name, detail.value
  end

  test 'only lists tags compatible with every selected issue type' do
    trackers = Tracker.limit(2).to_a
    assert_equal 2, trackers.size
    common_tag = RedmineIssueTag.create!(name: 'Tag comum', trackers: trackers)
    RedmineIssueTag.create!(name: 'Tag exclusiva', trackers: [trackers.first])
    issues = trackers.map {|tracker| Struct.new(:tracker_id).new(tracker.id)}

    available_ids = RedmineIssueTags.available_tags_for_issues(issues).pluck(:id)

    assert_equal [common_tag.id], available_ids
  end
end
