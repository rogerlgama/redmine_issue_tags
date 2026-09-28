class IssueTagsController < ApplicationController
  layout 'admin'
  accept_api_auth :index
  before_action :require_admin
  before_action :ensure_plugin_database
  before_action :find_tag, only: [:edit, :update, :destroy]

  def index
    @tags = RedmineIssueTag.sorted.includes(:taggings, :trackers)
    @roles = Role.givable.sorted
    @collaborative_roles = @roles.select {|role| permission_enabled_for?(role, :collaborate_issue_tags)}
    @assignment_roles = @roles.select {|role| permission_enabled_for?(role, :edit_issue_tags)}
    @collaborative_role_ids = @collaborative_roles.map(&:id)
    @assignment_role_ids = @assignment_roles.map(&:id)
    respond_to do |format|
      format.html
      format.json { render json: @tags.map { |tag| tag_json(tag) } }
    end
  end

  def new
    @tag = RedmineIssueTag.new(color: '#3b82f6')
  end

  def create
    @tag = RedmineIssueTag.new(tag_params)
    if @tag.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to action: :index
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit; end

  def update
    if @tag.update(tag_params)
      @tag.remove_incompatible_taggings!
      flash[:notice] = l(:notice_successful_update)
      redirect_to action: :index
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @tag.destroy
      flash[:notice] = l(:notice_successful_delete)
    else
      flash[:error] = l(:error_issue_tag_in_use)
    end
    redirect_to action: :index
  end

  def update_roles
    collaborative_ids = permitted_role_ids(params[:collaborative_role_ids])
    assignment_ids = permitted_role_ids(params[:assignment_role_ids])

    Role.transaction do
      Role.givable.find_each do |role|
        permissions = Array(role.permissions).map(&:to_sym)
        permissions = set_permission(permissions, :collaborate_issue_tags, collaborative_ids.include?(role.id))
        permissions = set_permission(permissions, :edit_issue_tags, assignment_ids.include?(role.id))
        role.update!(permissions: permissions)
      end
    end

    flash[:notice] = l(:notice_successful_update)
    redirect_to issue_tags_path
  end

  private

  def ensure_plugin_database
    return if RedmineIssueTags.database_ready?

    render plain: l(:error_issue_tags_database_not_ready), status: :service_unavailable
  end

  def find_tag
    @tag = RedmineIssueTag.find(params[:id])
  end

  def permission_enabled_for?(role, permission)
    Array(role.permissions).map(&:to_sym).include?(permission)
  end

  def permitted_role_ids(values)
    requested_ids = Array(values).map(&:to_i).select(&:positive?).uniq
    Role.givable.where(id: requested_ids).pluck(:id)
  end

  def set_permission(permissions, permission, enabled)
    enabled ? permissions | [permission] : permissions - [permission]
  end

  def tag_params
    params.require(:redmine_issue_tag).permit(:name, :description, :color, tracker_ids: [])
  end

  def tag_json(tag)
    {
      id: tag.id,
      name: tag.name,
      color: tag.color,
      description: tag.description,
      trackers: tag.trackers.order(:position).map { |tracker| {id: tracker.id, name: tracker.name} },
      issues_count: tag.taggings.size
    }
  end
end
