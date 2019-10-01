module ModelApiHelpers
  # For testing purposes, allow the request to
  # specify the user making the request by passing
  # in the id
  def self.credential request
    User.find_by(id: request.params[:user_id])
  end

  # The station serializer presents the additional option
  # to set the workers parameter to true in order to include
  # the users who work at the station
  def self.station_serializer **opts
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
  end
end
