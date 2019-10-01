require "openopus/core/api/engine"
require "openopus/core/api/permissions"

module Openopus
  module Core
    module Api
      class BaseApi
        @@exposed = {}
        @@on_extension = nil
        @@default_extension = nil
        @@default_options = {}
        @@graph_ql_types = {}
        @@graph_ql_mutation_response_types = {}

        def self.exposed
          @@exposed
        end

        def self.extension
          @@extension
        end

        def self.default_mount extension
          # Endpoints with no specified extension will
          # default to this mount point
          @@default_extension = extension
        end

        # Every exposed endpoint in the given block will be mounted on extension
        # instead of the default mount point
        #
        # Any given keyword arguments will be used as the default values
        # for the configuration arguments in exposed routes in the given
        # block
        def self.on extension, **opts
          @@on_extension = extension
          @@default_options = opts
          yield
        ensure
          @@on_extension = nil
          @@default_options = {}
        end


        def self.graph_ql_type route
          if not @@graph_ql_types[route]
            application_record = @@exposed[route][:application_record]
            available_query_parameters = @@exposed[route][:available_query_parameters]

            the_type = Class.new(GraphQL::Types::Relay::BaseObject) do
              graphql_name "#{application_record.to_s}Type"

              available_query_parameters.each do |q_param|
                field q_param.to_sym, GraphQL::Types::JSON, null: true
              end
            end

            @@graph_ql_types[route] = the_type
          end

          @@graph_ql_types[route]
        end

        def self.graph_ql_mutation_response_type route
          if not @@graph_ql_mutation_response_types[route]
            application_record = @@exposed[route][:application_record]
            the_model_type = graph_ql_type route
            field_name = application_record.to_s.underscore

            the_response_type = Class.new(GraphQL::Types::Relay::BaseObject) do
              graphql_name "#{application_record.to_s}MutationResponseType"
              field field_name.to_sym, the_model_type, null: true
              field :errors, [Types::UserErrorType], null: false
            end

            @@graph_ql_mutation_response_types[route] = the_response_type
          end

          @@graph_ql_mutation_response_types[route]
        end


        # Expose the given application record as a route on this defined api
        #
        # route defaults to the downcase version of the given class
        #   on 'test_api' { expose User }
        #   Users are queriable via 'test_api/user'
        #
        # credential is a Proc that takes the request from the controller and returns
        #   an object that may be used to determine access. It must be compatible
        #   with the given permissions.
        #   defaults to returning nil
        #
        # permissions will default to all OpenPermissions in a non production environment
        #   and will default to ClosedPermissions in production
        #
        # serializer is a Proc that returns a dict representation of a resource
        #   and will default to reflecting on the record and getting all columns
        #
        # query_by will default to reflecting on the record and getting all columns
        #   note that this gets you look up of multiple values for free by encoding the parameter as an array
        #   ?id[]=1&id[]=2 will be parsed by rails as a parameter of id = ["1", "2"]
        #
        # available_mutation_parameters will default to reflecting on the record and getting all columns except the id
        #
        # available_actions indicates which routes will be exposed via the symbols :create, :read, :update, :delete/:destroy.
        #   :delete and :destroy are interchangeable
        #   Defaults to all available.
        #   see config/routes.rb for how the symbols coorespond to the exposed routes.
        def self.expose application_record,
                        route: nil,
                        credential: nil,
                        permissions: nil,
                        serializer: nil,
                        query_by: nil,
                        available_mutation_parameters: nil,
                        available_actions: nil

          route ||= application_record.to_s.downcase


          query_by ||= (@@default_options[:query_by] or application_record.column_names)


          available_mutation_parameters ||= (
            @@default_options[:available_mutation_parameters] or
            application_record.column_names.select { |s| s != 'id' })


          available_actions ||= (
            @@default_options[:available_actions] or
            [:create, :read, :update, :delete])


          credential ||= (
            @@default_options[:credential] or
            Proc.new { |request| nil })


          serializer ||= (
            @@default_options[:serializer] or
            Proc.new { |resource|
              application_record.column_names
                .map { |column_name| [column_name, resource.send(column_name)] }
                .to_h
            })


          permissions ||= default_permissions


          extension = (@@on_extension or @@default_mount or '')
          full_route = "#{extension}/#{route}"

          @@exposed[full_route] = {
            application_record: application_record,
            permissions: permissions,
            serializer: serializer,
            available_query_parameters: query_by,
            available_mutation_parameters: available_mutation_parameters,
            available_actions: available_actions,
            credential: credential
          }
        end

        private
        def self.default_permissions
          if @@default_options[:permissions]
            @@default_options[:permissions]
          elsif Rails.env == 'production'
            Permissions::ClosedPermissions
          else
            Permissions::OpenPermissions
          end
        end

      end
    end
  end
end
