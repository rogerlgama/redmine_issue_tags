require File.expand_path('../test_helper', __dir__)

class IssueTagsContextMenuTest < Redmine::ControllerTest
  tests ContextMenusController

  test 'shows compatible tags in the issue context menu' do
    issue = Issue.find(1)
    tag = RedmineIssueTag.create!(name: 'Contexto', trackers: [issue.tracker])
    @request.session[:user_id] = 1

    get :issues, params: {ids: [issue.id]}

    assert_response :success
    assert_select 'li.folder > a.submenu', text: I18n.t(:field_issue_tags)
    assert_select 'a[data-method="patch"]', text: tag.name do |links|
      assert_includes links.first['href'], 'issue_tag_bulk%5Boperation%5D=add'
      assert_includes links.first['href'], "issue_tag_bulk%5Btag_ids%5D%5B%5D=#{tag.id}"
    end
  end
end

class IssueTagsBulkEditTest < Redmine::ControllerTest
  tests IssuesController

  test 'renders tag operations and compatible checkboxes in bulk edit' do
    issues = Issue.where(id: [1, 2]).to_a
    tag = RedmineIssueTag.create!(name: 'Edição em massa', trackers: issues.map(&:tracker).uniq)
    @request.session[:user_id] = 1

    get :bulk_edit, params: {ids: issues.map(&:id)}

    assert_response :success
    assert_select 'select[name="issue_tag_bulk[operation]"]' do
      assert_select 'option[value="add"]', text: I18n.t(:label_issue_tag_bulk_add)
      assert_select 'option[value="remove"]', text: I18n.t(:label_issue_tag_bulk_remove)
      assert_select 'option[value="replace"]', text: I18n.t(:label_issue_tag_bulk_replace)
    end
    assert_select "input[name='issue_tag_bulk[tag_ids][]'][value='#{tag.id}']"
  end

  test 'adds a tag to all selected issues without replacing existing tags' do
    issues = Issue.where(id: [1, 2]).to_a
    trackers = issues.map(&:tracker).uniq
    existing_tag = RedmineIssueTag.create!(name: 'Mantida', trackers: [issues.first.tracker])
    added_tag = RedmineIssueTag.create!(name: 'Incluída em massa', trackers: trackers)
    RedmineIssueTagging.create!(issue: issues.first, tag: existing_tag, author: User.find(1))
    @request.session[:user_id] = 1

    post :bulk_update,
         params: {
           ids: issues.map(&:id),
           issue: {},
           issue_tag_bulk: {operation: 'add', tag_ids: [added_tag.id]}
         }

    assert_response :found
    assert_equal 2, RedmineIssueTagging.where(issue_tag_id: added_tag.id, issue_id: issues.map(&:id)).count
    assert RedmineIssueTagging.exists?(issue_id: issues.first.id, issue_tag_id: existing_tag.id)
    issues.each do |issue|
      assert issue.journals.joins(:details).exists?(journal_details: {prop_key: 'issue_tags'})
    end
  end
end
