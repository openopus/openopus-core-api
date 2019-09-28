class OrganizationPermissions < Openopus::Core::Api::Permissions::ClosedPermissions
  def self.read(credential:, resource:)
    # All organizations are freely read
    true
  end

  def self.update(**opts)
    user = opts[:credential]
    organization = opts[:resource]

    # Only an administrator who is employed at an organization may update it
    user and user.role == "admin" and organization.users.include?(user)
  end
end


class ModelsApi < Openopus::Core::Api::BaseApi
  on '/test_api' do
    credential = Proc.new do |request|
      User.find_by(id: request.params[:user_id])
    end

    expose Organization,
           available_actions: [:read, :update],
           query_by: [:name, :id],
           permissions: OrganizationPermissions,
           credential: credential

    expose Region
    # expose Station
    # expose User
  end
end
