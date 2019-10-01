require_relative './model_permissions'
require_relative './model_api_helpers'

class ModelsApi < Openopus::Core::Api::BaseApi

  on '/test_api', credential: ModelApiHelpers.method(:credential) do

    expose Organization,
           available_actions: [:read, :update],
           query_by: [:name, :id],
           permissions: ModelPermissions::OrganizationPermissions

    expose Region,
           permissions: ModelPermissions::RegionPermissions

    expose Station,
           serializer: ModelApiHelpers.method(:station_serializer)

  end
end
