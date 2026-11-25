require File.expand_path('../test_helper', __dir__)

class IssueTagsApiTest < Redmine::ControllerTest
  tests IssueTagsApiController

  test 'allows a non administrator with an api key to list tags' do
    user = User.find(2)
    tag = RedmineIssueTag.create!(name: 'API para usuário', trackers: [Tracker.first])
    @request.headers['X-Redmine-API-Key'] = user.api_key

    with_settings rest_api_enabled: '1' do
      get :index, params: {format: :json}
    end

    assert_response :success
    payload = JSON.parse(response.body)
    assert_includes payload.fetch('tags').map {|item| item.fetch('id')}, tag.id
  end

  test 'rejects an unauthenticated plugin api request' do
    with_settings rest_api_enabled: '1' do
      get :index, params: {format: :json}
    end

    assert_response :unauthorized
  end
end

class IssueTagsCatalogApiTest < Redmine::ControllerTest
  tests IssueTagsController

  test 'allows a non administrator with an api key to use the legacy json catalog' do
    user = User.find(2)
    tag = RedmineIssueTag.create!(name: 'Catálogo JSON', trackers: [Tracker.first])
    @request.headers['X-Redmine-API-Key'] = user.api_key

    with_settings rest_api_enabled: '1' do
      get :index, params: {format: :json}
    end

    assert_response :success
    assert_includes JSON.parse(response.body).map {|item| item.fetch('id')}, tag.id
  end

  test 'keeps the html catalog restricted to administrators' do
    @request.session[:user_id] = 2

    get :index

    assert_response :forbidden
  end
end
