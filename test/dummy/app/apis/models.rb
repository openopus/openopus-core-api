ClosedPermissions = Openopus::Core::Api::Permissions::ClosedPermissions

class OrganizationPermissions < ClosedPermissions
  def self.read(**opts)
    # All organizations are freely read
    true
  end

  # Only an administrator who is employed at an organization may update it
  def self.update(**opts)
    user = opts[:credential]
    organization = opts[:resource]

    user and user.role == "admin" and organization.employs?(user)
  end
end

class RegionPermissions < ClosedPermissions
  # User's can only read regions if they're employed
  # at the region's organization
  def self.read(**opts)
    user = opts[:credential]
    region = opts[:resource]

    user and region.organization.employs?(user)
  end

  def self.create *args, **opts
    modify *args, **opts
  end

  def self.update *args, **opts
    modify *args, **opts
  end

  def self.delete *args, **opts
    modify *args, **opts
  end

  private
  def self.modify(**opts)
    user = opts[:credential]
    region = opts[:resource]

    user and user.role == "admin" and region.organization.employs?(user)
  end
end


class ModelsApi < Openopus::Core::Api::BaseApi
  # For testing purposes, allow the request to
  # specify the user making the request by passing
  # in the id
  credential = Proc.new do |request|
    User.find_by(id: request.params[:user_id])
  end

  # The station serializer presents the additional option
  # to set the workers parameter to true in order to include
  # the users who work at the station
  station_serializer = Proc.new { |**opts|
    station = opts[:resource]
    request = opts[:request]

    serialized = Station.column_names
                   .map { |column_name| [column_name, station.send(column_name)] }
                   .to_h

    workers_requested = ActiveModel::Type::Boolean.new.cast(request.params["workers"])

    if workers_requested
      workers = station.station_roles.map { |role|
        {
          "worker" => role.user.name,
          "job_title" => role.job_title
        }
      }

      serialized["workers"] = workers
    end

    serialized
  }

  on '/test_api', credential: credential do
    expose Organization,
           available_actions: [:read, :update],
           query_by: [:name, :id],
           permissions: OrganizationPermissions

    expose Region,
           permissions: RegionPermissions

    expose Station,
           serializer: station_serializer
  end
end
