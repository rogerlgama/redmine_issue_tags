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
end
