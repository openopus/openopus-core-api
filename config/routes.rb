Openopus::Core::Api::Engine.routes.draw do
  scope format: false, defaults: { format: 'json' } do
    match '*path' => "openopus/core/api/base#options", :via => [:options]
  
    # Authentication routes (which will be removed).
    namespace "authentication" do 
      get 'facebook' 
      post 'facebook'
      get 'login'
      post 'login'
      get 'signup'
      post 'signup'
      get 'logout'
      post 'logout'
      post 'change_password'
      post 'reset_password'
      post 'recover_password'
    end

    # Miscellaneous routes.
    get    'version'                    => 'openopus/core/api/misc#version'
    get    'whoami'                     => 'openopus/core/api/misc#whoami'

    # RESTful API routes.
    get    '(:namespace/):model/:id'    => 'openopus/core/api/rest#read',    constraints: { id: /(\h|-)*/, model: /\D+/ }
    match  '(:namespace/):model/:id'    => 'openopus/core/api/rest#update',  constraints: { id: /(\h|-)*/, model: /\D+/ }, via: [:post, :put, :patch]
    delete '(:namespace/):model(/:id)'  => 'openopus/core/api/rest#destroy', constraints: { id: /(\h|-)*/, model: /\D+/ }
    get    '(:namespace/):model'        => 'openopus/core/api/rest#index',   constraints: { model: /\D+/ }
    post   '(:namespace/):model'        => 'openopus/core/api/rest#create',  constraints: { model: /\D+/ }
  end
end
