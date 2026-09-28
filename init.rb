# frozen_string_literal: true

require_relative 'lib/redmine_issue_tags'

Redmine::Plugin.register :redmine_issue_tags do
  name 'Redmine Issue Tags'
  author 'Roger Gama'
  author_url 'https://github.com/rogerlgama/redmine_issue_tags'
  description 'Tags pesquisáveis para tarefas do Redmine'
  version '0.5.2'
  url 'https://github.com/rogerlgama/redmine_issue_tags'
  requires_redmine version_or_higher: '6.0.0'

  permission :edit_issue_tags, {}, require: :member
  permission :collaborate_issue_tags,
             {issue_tag_collaborations: [:create, :edit, :update]},
             require: :member

  menu :admin_menu, :issue_tags,
       {controller: 'issue_tags', action: 'index'},
       caption: :label_issue_tags,
       html: {class: 'icon icon-issue'}
end
