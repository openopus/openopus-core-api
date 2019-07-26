# base_controller.rb: -*- Ruby -*-  DESCRIPTIVE TEXT.
# 
#  Copyright (c) 2019 Brian J. Fox Opus Logica, Inc.
#  Author: Brian J. Fox (bfox@opuslogica.com)
#  Birthdate: Sun Jul 21 12:32:20 2019.
module Openopus
  module Core
    module Api
      class BaseController < ::ApplicationController
        before_action :load_config_params
        before_action :cors_set_access_control_headers
        before_action :cors_preflight_check
        before_action :api_setup

        rescue_from ActiveRecord::RecordNotFound, with: :render_404

        def load_config_params
          @token_name = Openopus::Core::Api.config.token_name
          @token_name = "api-token"
        end
        
        def options
        end

        # For all responses in this controller, return the CORS access control headers.
        def cors_set_access_control_headers
          response.headers['Access-Control-Allow-Origin'] = '*'
          response.headers['Access-Control-Allow-Credentials'] = 'true'
          response.headers['Access-Control-Allow-Methods'] = 'GET, PUT, POST, DELETE, OPTIONS, PATCH'
          response.headers['Access-Control-Max-Age'] = "1728000"
          response.headers['Access-Control-Allow-Headers'] = 'X-CSRF-Token, X-Requested-With, X-Prototype-Version, content-type, ' + @token_name
        end

        # If this is a preflight OPTIONS request, then short-circuit the
        # request, return only the necessary headers and return an empty
        # text/plain.
        def cors_preflight_check
          if request.method == "OPTIONS"
            headers['Access-Control-Allow-Origin'] = '*'
            headers['Access-Control-Allow-Methods'] = 'GET, PUT, POST, DELETE, OPTIONS, PATCH'
            headers['Access-Control-Allow-Headers'] = 'X-CSRF-Token, X-Requested-With, X-Prototype-Version, content-type, ' + @token_name
            headers['Access-Control-Max-Age'] = '1728000'
            render(plain: '', content_type: 'text/plain')
            false
          end
          true
        end

        def authorized?(action, resource)
          Openopus::Core::Api.config.authorize_with.call(@authenticated, action, resource)
        end

        def self.promiscuous_authenticator(options)
          true
        end

        def api_setup
          @request = request
          @params = params
          @action = params[:action]
          @controller = params[:controller]
          @arguments = params[:rest]

          @authenticated = Openopus::Core::Api.config.request_authenticator.call({ request: @request, params: @params })
        end

        def render_error(error_code, extra_hash_members={})
          error = ApiError.find_by_code(error_code)
          hash = { :error => error.as_json({}) }.merge(extra_hash_members)
          render_result(hash, error.status_code)
        end

        def render_result(hash={error: "unknown error!"}, status=200)
          render(json: hash.as_json({}), status: status)
        end

        @private
        def render_404
          errhash = { :error =>  { description: "Record not found" , code: 404, status_code: 404 } }
          render :json => errhash , :status => 404
        end
      end
    end
  end
end
