module RedmineIssueTags
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_issues_form_details_bottom,
              partial: 'issue_tags/issue_form'
    render_on :view_issues_show_details_bottom,
              partial: 'issue_tags/issue_show'
    render_on :view_layouts_base_html_head,
              partial: 'issue_tags/assets'

    def controller_issues_new_after_save(context = {})
      persist_tags(context)
    end

    def controller_issues_edit_after_save(context = {})
      persist_tags(context)
    end

    private

    def persist_tags(context)
      return unless RedmineIssueTags.database_ready?

      issue = context[:issue]
      params = context[:params]
      return unless issue && params && RedmineIssueTags.can_assign_tags?(User.current, issue.project)
      return unless params.key?(:redmine_issue_tag_ids)

      ids = Array(params[:redmine_issue_tag_ids]).map(&:to_i).select(&:positive?).uniq
      allowed_ids = RedmineIssueTag
                    .active
                    .joins(:trackers)
                    .where(id: ids, trackers: {id: issue.tracker_id})
                    .pluck(:id)
      old_names = RedmineIssueTags.tags_for(issue).order(:name).pluck(:name)

      RedmineIssueTagging.transaction do
        RedmineIssueTagging.where(issue_id: issue.id).where.not(issue_tag_id: allowed_ids).delete_all
        existing_ids = RedmineIssueTagging.where(issue_id: issue.id, issue_tag_id: allowed_ids).pluck(:issue_tag_id)
        (allowed_ids - existing_ids).each do |tag_id|
          RedmineIssueTagging.create!(issue_id: issue.id, issue_tag_id: tag_id, author_id: User.current.id)
        end
      end

      new_names = RedmineIssueTags.tags_for(issue).order(:name).pluck(:name)
      RedmineIssueTags.record_tag_change(issue, User.current, old_names, new_names)
    end
  end
end
