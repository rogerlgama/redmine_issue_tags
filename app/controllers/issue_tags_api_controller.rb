class IssueTagsApiController < ApplicationController
  accept_api_auth :index, :show, :issues, :issue_tags, :roles
  before_action :require_admin
  before_action :ensure_plugin_database
  before_action :find_tag, only: [:show, :issues]
  before_action :find_issue, only: :issue_tags

  def index
    tags = RedmineIssueTag.sorted.includes(:trackers, :taggings).to_a
    render json: {
      tags: tags.map {|tag| tag_payload(tag)},
      total_count: tags.size
    }
  end

  def show
    render json: {tag: tag_payload(@tag)}
  end

  def issues
    scope = Issue.visible
                 .where(id: RedmineIssueTagging.where(issue_tag_id: @tag.id).select(:issue_id))
                 .includes(:project, :tracker, :status, :assigned_to)
                 .order(id: :desc)
    total_count = scope.count
    issues = scope.offset(api_offset).limit(api_limit)

    render json: {
      tag: basic_tag_payload(@tag),
      issues: issues.map {|issue| issue_payload(issue)},
      total_count: total_count,
      limit: api_limit,
      offset: api_offset
    }
  end

  def issue_tags
    tags = RedmineIssueTags.tags_for(@issue).order(:name).to_a
    render json: {
      issue: {
        id: @issue.id,
        subject: @issue.subject,
        project: {id: @issue.project_id, name: @issue.project.name}
      },
      tags: tags.map {|tag| basic_tag_payload(tag)},
      total_count: tags.size
    }
  end

  def roles
    roles = Role.givable.sorted.map do |role|
      permissions = Array(role.permissions).map(&:to_sym)
      {
        id: role.id,
        name: role.name,
        create_edit_tags: permissions.include?(:collaborate_issue_tags),
        add_remove_tags: permissions.include?(:edit_issue_tags)
      }
    end

    render json: {roles: roles, total_count: roles.size}
  end

  private

  def ensure_plugin_database
    return if RedmineIssueTags.database_ready?

    render json: {error: I18n.t(:error_issue_tags_database_not_ready)}, status: :service_unavailable
  end

  def find_tag
    @tag = RedmineIssueTag.includes(:trackers, :taggings).find_by(id: params[:id])
    return if @tag

    render json: {error: I18n.t(:error_issue_tag_not_found)}, status: :not_found
  end

  def find_issue
    @issue = Issue.visible.includes(:project).find_by(id: params[:issue_id])
    return if @issue

    render json: {error: I18n.t(:error_issue_tag_issue_not_found)}, status: :not_found
  end

  def tag_payload(tag)
    basic_tag_payload(tag).merge(
      trackers: tag.trackers.sort_by(&:position).map {|tracker| {id: tracker.id, name: tracker.name}},
      issues_count: tag.taggings.size,
      created_on: tag.created_at,
      updated_on: tag.updated_at
    )
  end

  def basic_tag_payload(tag)
    {
      id: tag.id,
      name: tag.name,
      description: tag.description,
      color: tag.color
    }
  end

  def issue_payload(issue)
    {
      id: issue.id,
      subject: issue.subject,
      project: {id: issue.project_id, name: issue.project.name},
      tracker: {id: issue.tracker_id, name: issue.tracker.name},
      status: {id: issue.status_id, name: issue.status.name},
      assigned_to: issue.assigned_to && {id: issue.assigned_to_id, name: issue.assigned_to.name},
      created_on: issue.created_on,
      updated_on: issue.updated_on
    }
  end

  def api_limit
    @api_limit ||= begin
      value = params[:limit].to_i
      value = 100 if value <= 0
      [value, 1000].min
    end
  end

  def api_offset
    @api_offset ||= [params[:offset].to_i, 0].max
  end
end
