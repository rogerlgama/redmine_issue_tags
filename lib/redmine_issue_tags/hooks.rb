module RedmineIssueTags
  class Hooks < Redmine::Hook::ViewListener
    render_on :view_issues_form_details_bottom,
              partial: 'issue_tags/issue_form'
    render_on :view_issues_show_details_bottom,
              partial: 'issue_tags/issue_show'
    render_on :view_issues_bulk_edit_details_bottom,
              partial: 'issue_tags/bulk_edit'
    render_on :view_issues_context_menu_end,
              partial: 'issue_tags/context_menu'
    render_on :view_layouts_base_html_head,
              partial: 'issue_tags/assets'

    def controller_issues_new_after_save(context = {})
      persist_tags(context)
    end

    def controller_issues_edit_after_save(context = {})
      persist_tags(context)
    end

    def controller_issues_bulk_edit_before_save(context = {})
      return unless RedmineIssueTags.database_ready?

      issue = context[:issue]
      params = context[:params]
      return unless issue && params && params[:copy].blank?

      bulk_params = params[:issue_tag_bulk]
      return unless bulk_params

      operation = bulk_params[:operation].to_s
      return unless RedmineIssueTags::TAG_CHANGE_OPERATIONS.include?(operation)

      RedmineIssueTags.queue_issue_tag_change!(
        issue,
        User.current,
        bulk_params[:tag_ids],
        operation: operation
      )
    end

    private

    def persist_tags(context)
      return unless RedmineIssueTags.database_ready?

      issue = context[:issue]
      params = context[:params]
      return unless issue && params && RedmineIssueTags.can_assign_tags?(User.current, issue.project)
      return unless params.key?(:redmine_issue_tag_ids)

      RedmineIssueTags.change_issue_tags!(
        issue,
        User.current,
        params[:redmine_issue_tag_ids],
        operation: :replace
      )
    end
  end
end
