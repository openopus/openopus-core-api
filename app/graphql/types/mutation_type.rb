def resource_errors_to_gql_errors resource
  resource.errors.map do |attribute, message|
    path = ["attributes", attribute.camelize]
    {
      path: path,
      message: message,
    }
  end
end

def resource_not_found_error field_name, id
  {
    message: "No #{field_name} with id #{id} found",
    path: ['attributes', 'id']
  }
end

module Types
  class MutationType < Types::BaseObject
    Openopus::Core::Api::BaseApi.exposed.each do |route, opts|
      application_record            = opts[:application_record]
      available_mutation_parameters = opts[:available_mutation_parameters]
      permissions                   = opts[:permissions]
      # TODO same field name issue as in QueryType
      field_name                    = application_record.to_s.underscore

      the_response_type = Openopus::Core::Api::BaseApi.graph_ql_mutation_response_type route


      # Update on the model name prefixed with update_.
      # Looks up the model by id and updates according
      # to the rest of the given parameters
      field "update_#{field_name}".to_sym, the_response_type, null: false do
        argument :id, ID, required: true

        available_mutation_parameters.each do |q_param|
          argument q_param.to_sym, GraphQL::Types::JSON, required: false
        end
      end


      define_method("update_#{field_name}".to_sym) { |**opts|
        id = opts[:id]
        resource = application_record.find_by(id: id)
        errors = []

        # TODO
        credential = nil

        if resource and not permissions.update(credential: credential, resource: resource)
          resource = nil
          # Not sure if not found is the right thing to reply with when really it is not permissioned
          errors << resource_not_found_error
        elsif resource and not resource.update(opts)
          errors += resource_errors_to_gql_errors(resource)
        else
          errors << resource_not_found_error
        end

        {
          field_name.to_sym => resource,
          errors: errors
        }
      }


      # Create on the model name prefixed with create_.
      field "create_#{field_name}".to_sym, the_response_type, null: false do
        available_mutation_parameters.each do |q_param|
          argument q_param.to_sym, GraphQL::Types::JSON, required: false
        end
      end

      define_method("create_#{field_name}".to_sym) { |**opts|
        resource = application_record.new(opts)
        errors = []

        # TODO
        credential = nil

        if not permissions.create(resource: resource, credential: credential)
          resource = nil
          errors << {
            message: "Not allowed to create #{field_name}",
            path: ['Permissions']
          }
        else
          resource.save

          if not resource.persisted?
            resource = nil
            errors += resource_errors_to_gql_errors(resource)
          end
        end

        {
          field_name.to_sym => resource,
          errors: errors
        }
      }


      # Destroy or delete on the model name prefixed with the corresponding verb
      field "destroy_#{field_name}".to_sym, ExpungeResultType, null: false do
        argument :id, ID, required: true
      end


      field "delete_#{field_name}".to_sym, ExpungeResultType, null: false do
        argument :id, ID, required: true
      end

      expunge_resource = Proc.new { |**opts|
        id = opts[:id]
        errors = []
        success = nil
        resource = application_record.find_by(id: opts[:id])

        # TODO
        credential = nil

        if resource and not permissions.destroy(credential: credential, resource: resource)
          success = false
          errors << {
            message: "Not allowed to expunge #{field_name}",
            path: ['Permissions']
          }
        elsif resource
          if resource.destroy
            success = true
          else
            success = false
            errors += resource_errors_to_gql_errors(resource)
          end
        else
          success = false

          errors << {
            message: "No #{field_name} with id #{id} found",
            path: ['attributes', 'id']
          }
        end

        {
          success: success,
          errors: errors
        }
      }

      define_method("destroy_#{field_name}".to_sym, &expunge_resource)
      define_method("delete_#{field_name}".to_sym, &expunge_resource)
    end
  end
end
