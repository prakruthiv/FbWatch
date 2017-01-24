require 'sidekiq/web'

Fbwatch::Application.routes.draw do
  # general actions
  root :to => 'home#index_groups'
  
  get "apitest", to: 'apitest#index'

  # index
  get   "tasks",            to: 'tasks#index',        as: 'tasks'
  patch 'tasks/:id/resume', to: 'tasks#resume_task',  as: 'resume_task'
  patch 'tasks/:id/error',  to: 'tasks#mark_error',   as: 'mark_task_error'

  # sync actions
  get "sync/all", to: 'sync#all', as: 'sync_all'
  get "sync(/:name)", to: 'sync#resource', :constraints => { :name => /[^\/]+/ }, as: 'sync'
  get "sync/clear/:name", to: 'sync#clear', :constraints => { :name => /[^\/]+/ }, as: 'sync_clear'
  
  # resource actions
  get 'resources(/:p)' => 'resources#index', as: 'resources_index', constraints: { p: /[0-9]+/ }

  get   'resource/:username/disable',       to: 'resources#disable',            as: 'sync_disable',       :constraints => { :username => /[^\/]+/ }
  get   'resource/:username/enable',        to: 'resources#enable',             as: 'sync_enable',        :constraints => { :username => /[^\/]+/ }
  get   'resource/:username/details(/:p)',  to: 'resources#details',            as: 'resource_details',   :constraints => { :username => /[^\/]+/}
  get   'resource/:username',               to: 'resources#overview',           as: 'resource_overview',  :constraints => { :username => /[^\/]+/}
  post  'resource/:id/groups',              to: 'resources#add_to_group',       as: 'add_resource_to_group'
  patch 'resource/:id/clear_last_synced',   to: 'resources#clear_last_synced',  as: 'clear_last_synced'
  get   'resources/search/name',            to: 'resources#search_for_name',    as: 'search_resource_names'
  patch 'resource/:id/keywords',            to: 'resources#change_keywords',    as: 'keywords'
  patch 'resource/:id/color',               to: 'resources#change_color',       as: 'node_color'
  get   'resource/:username/clean',         to: 'resources#show_clean_up',      as: 'clean_up_resource',  :constraints => { :username => /[^\/]+/ }
  patch 'resource/:username/clean',         to: 'resources#do_clean_up',        as: 'do_clean_up',        :constraints => { :username => /[^\/]+/ }
  get   'resource/:id/graph/:group_id',     to: 'network_graph#for_resource',   as: 'resource_graph'
  get   'resource/:id/google_graph/:group_id', to: 'network_graph#google_for_resource', as: 'resource_google_graph'
  patch 'resources/color',                  to: 'resources#change_color_batch', as: 'node_color_batch'
  get   'resources/color',                  to: 'resources#show_change_color_batch', as: 'show_node_color_batch'
  resources :resources, only: [:create, :destroy, :update]

  # metrics
  patch 'resource/:username/metrics',   to: 'metrics#resource',             as: 'run_metrics',    :constraints => { :username => /[^\/]+/ }
  patch 'group/:id/metrics',            to: 'metrics#group',                as: 'group_metrics'
  patch 'group/:id/google_metrics',     to: 'metrics#google',               as: 'google_metrics'
  get   'google_captcha',               to: 'metrics#solve_captcha',        as: 'solve_captcha'
  get   'google_captcha/code',          to: 'metrics#show_google_captcha',  as: 'show_captcha'
  post  'google_captcha/code',          to: 'metrics#save_google_captcha',  as: 'save_captcha'

  # login actions
  get "login", to: 'sessions#login'
  get '/auth/:provider/callback', to: 'sessions#create'
  get '/auth/failure', to: 'sessions#failure'
  
  # group actions
  resources :resource_groups, only: [:create, :destroy, :update]
  get     'group/:id',                        to: 'resource_groups#details',                  as: 'resource_group_details'
  post    'group/mass',                       to: 'resource_groups#mass_assign',              as: 'resource_group_mass_assign'
  patch   'group/:id/activate',               to: 'resource_groups#activate',                 as: 'activate_group'
  patch   'group/:id/deactivate',             to: 'resource_groups#deactivate',               as: 'deactivate_group'
  patch   'group/:id/clear',                  to: 'sync#clear_group',                         as: 'clear_group'
  patch   'group/:id/sync',                   to: 'sync#group',                               as: 'sync_group'
  delete  'group/:id/resource/:resource_id',  to: 'resource_groups#remove_resource',          as: 'remove_resource_from_group'
  post    'group/:id/add',                    to: 'resource_groups#add_resource',             as: 'resource_group_add_resource'
  get     'group/:id/graph',                  to: 'network_graph#for_resource_group',         as: 'resource_group_graph'
  get     'group/:id/google_graph',           to: 'network_graph#google_for_resource_group',  as: 'resource_group_google_graph'
  get     'group/:id/report',                 to: 'resource_groups#report',                   as: 'resource_group_report'

  mount Sidekiq::Web, at: '/sidekiq'
end
