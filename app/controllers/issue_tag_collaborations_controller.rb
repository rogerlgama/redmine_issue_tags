class IssueTagCollaborationsController < ApplicationController
  before_action :find_project
  before_action :find_tag, only: [:edit, :update]
  before_action :authorize_collaboration
  before_action :find_return_issue, only: [:edit, :update]

  def create
    tracker = @project.trackers.find(params[:tracker_id])
    @tag = RedmineIssueTag.new(collaborative_tag_params)
    @tag.trackers = [tracker]

    if @tag.save
      render json: {
        id: @tag.id,
        name: @tag.name,
        description: @tag.description,
        color: @tag.color,
        edit_url: edit_project_issue_tag_collaboration_path(@project, @tag)
      }, status: :created
    else
      render json: {errors: @tag.errors.full_messages}, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @tag.update(collaborative_tag_params)
      flash[:notice] = l(:notice_successful_update)
      redirect_to(@return_issue ? issue_path(@return_issue) : project_path(@project))
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def find_project
    @project = Project.find_by(id: params[:project_id]) || Project.find_by!(identifier: params[:project_id])
  end

  def authorize_collaboration
    deny_access unless RedmineIssueTags.can_collaborate_tags?(User.current, @project)
  end

  def find_tag
    @tag = RedmineIssueTag.find(params[:id])
    project_tracker_ids = @project.trackers.pluck(:id)
    deny_access unless @tag.trackers.where(id: project_tracker_ids).exists?
  end

  def find_return_issue
    @return_issue = @project.issues.find_by(id: params[:issue_id])
  end

  def collaborative_tag_params
    params.require(:redmine_issue_tag).permit(:name, :description, :color)
  end

end
