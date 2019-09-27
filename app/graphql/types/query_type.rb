module Types
  class QueryType < Types::BaseObject
    Openopus::Core::Api::BaseApi.exposed.each do |route, opts|
      application_record = opts[:application_record]
      available_query_parameters = opts[:available_query_parameters]
      permissions = opts[:permissions]
      serializer = params[:serializer]

      the_type = Openopus::Core::Api::BaseApi.graph_ql_type route

      # TODO if the same model exposes endpoints on multiple different routes,
      # this will still use the same field name.
      #
      # We need some way to distinguish between endpoints that are supposed
      # to be mounted on different endpoints
      field_name = application_record.to_s.underscore

      # Look up on the singular name of the model by id
      field field_name.to_sym, the_type, null: true do
        argument :id, ID, required: true
      end

      define_method(field_name.to_sym) { |**opts|
        id = opts[:id]
        resource = application_record.find_by(id: id)

        # TODO
        credential = nil

        if resource and not permissions.read(
                              credential: credential,
                              resource: resource)
            resource = nil
        end

        if resource
          serializer.call(resource)
        else
          nil
        end
      }

      # Query on the plural name of the model for all models which match the given parameters
      field field_name.pluralize.to_sym, [the_type], null: true do
        available_query_parameters.each do |q_param|
          argument q_param.to_sym, GraphQL::Types::JSON, required: false
        end
      end

      define_method(field_name.pluralize.to_sym) { |**opts|
        # TODO
        credential = nil

        application_record
          .where(opts)
          .select { |resource| permissions.read(credential: credential, resource: resource) }
          .map { |resource| serializer.call(resource) }
      }
    end
  end
end
