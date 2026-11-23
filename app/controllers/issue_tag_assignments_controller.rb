class IssueTagAssignmentsController < ApplicationController
  accept_api_auth :show, :update
  before_action :find_issue
  before_action :ensure_plugin_database
  before_action :authorize_tag_edit, only: :update

  def show
    render json: payload
  end

  def update
    ids = Array(params.dig(:tags, :ids)).map(&:to_i).select(&:positive?).uniq
    RedmineIssueTags.change_issue_tags!(@issue, User.current, ids, operation: :replace)
    render json: payload
  end

  private

  def ensure_plugin_database
    return if RedmineIssueTags.database_ready?

    render json: {error: I18n.t(:error_issue_tags_database_not_ready)}, status: :service_unavailable
  end

  def find_issue
    @issue = Issue.visible.find(params[:issue_id])
    @project = @issue.project
  end

  def authorize_tag_edit
    deny_access unless User.current.allowed_to?(:edit_issue_tags, @project)
  end

  def payload
    {
      issue_id: @issue.id,
      tags: RedmineIssueTags.tags_for(@issue).order(:name).map { |tag| {id: tag.id, name: tag.name, color: tag.color} }
    }
  end
end
