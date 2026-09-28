patch 'issue_tags/roles', to: 'issue_tags#update_roles', as: :issue_tag_roles
resources :issue_tags, except: [:show]

scope 'api/issue_tags', defaults: {format: :json} do
  get 'tags', to: 'issue_tags_api#index'
  get 'tags/:id', to: 'issue_tags_api#show'
  get 'tags/:id/issues', to: 'issue_tags_api#issues'
  get 'issues/:issue_id/tags', to: 'issue_tags_api#issue_tags'
  get 'roles', to: 'issue_tags_api#roles'
end

resources :projects, only: [] do
  resources :issue_tag_collaborations,
            only: [:create, :edit, :update],
            path: 'issue-tags'
end
get 'issues/:issue_id/tags',
    to: 'issue_tag_assignments#show',
    as: :issue_tags_assignment
put 'issues/:issue_id/tags',
    to: 'issue_tag_assignments#update'
patch 'issues/:issue_id/tags',
      to: 'issue_tag_assignments#update'
