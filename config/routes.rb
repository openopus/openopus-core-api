Rails.application.routes.draw do
  Dir.glob(Rails.root.join('app', 'apis', '*.rb')) do |api_file|
    require Rails.root.join('app', 'apis', api_file)
  end

  Openopus::Core::Api::BaseApi.exposed.each do |route, opts|
    available_actions = opts[:available_actions]

    if available_actions.include? :create
      post   "#{route}"     => 'rest#create'  , defaults: opts
    end

    if available_actions.include? :read
      get    "#{route}"     => 'rest#index'   , defaults: opts
      get    "#{route}/:id" => 'rest#show'    , defaults: opts
    end

    if available_actions.include? :update
      put    "#{route}/:id" => 'rest#update'  , defaults: opts
      patch  "#{route}/:id" => 'rest#update'  , defaults: opts
    end

    if available_actions.include?(:delete) or available_actions.include?(:destroy)
      delete "#{route}/:id" => 'rest#destroy' , defaults: opts
    end
  end

  post "/graphql", to: "graphql#execute"

  if Rails.env.development?
    mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  end
end
