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
    valid_ids = RedmineIssueTag
                .active
                .joins(:trackers)
                .where(id: ids, trackers: {id: @issue.tracker_id})
                .pluck(:id)
    old_names = RedmineIssueTags.tags_for(@issue).order(:name).pluck(:name)

    RedmineIssueTagging.transaction do
      RedmineIssueTagging.where(issue_id: @issue.id).where.not(issue_tag_id: valid_ids).delete_all
      existing_ids = RedmineIssueTagging.where(issue_id: @issue.id, issue_tag_id: valid_ids).pluck(:issue_tag_id)
      (valid_ids - existing_ids).each do |tag_id|
        RedmineIssueTagging.create!(issue_id: @issue.id, issue_tag_id: tag_id, author_id: User.current.id)
      end
    end

    new_names = RedmineIssueTags.tags_for(@issue).order(:name).pluck(:name)
    RedmineIssueTags.record_tag_change(@issue, User.current, old_names, new_names)
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
