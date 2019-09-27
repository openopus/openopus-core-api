class UnauthorizedError < StandardError
end

class RestController < ApplicationController
  rescue_from UnauthorizedError do |e|
    render json: {}, status: :unauthorized
  end

  def index
    query_by = params
                 .slice(*available_query_parameters)
                 .permit(*available_query_parameters)

    render json: application_record
             .where(query_by)
             .select { |resource| permissions.read(credential: credential, resource: resource) }
             .map { |resource| serializer(resource) }
  end

  def create
    create_by = params
                  .slice(*available_mutation_parameters)
                  .permit(*available_mutation_parameters)

    resource = application_record.new(create_by)

    if not permissions.create(resource: resource, credential: credential)
      return render json: {}, status: :forbidden
    end

    resource.save

    if resource.persisted?
      render json: serializer(resource)
    else
      errors = resource.errors.full_messages
      render json: errors, status: :forbidden
    end
  end

  def show
    process_resource do |resource|
      if permissions.read credential: credential, resource: resource
        render json: serializer(resource)
      else
        raise UnauthorizedError.new('Not allowed')
      end
    end
  end

  def update
    process_resource do |resource|
      if permissions.update credential: credential, resource: resource

        update_by = params
                      .slice(*available_mutation_parameters)
                      .permit(*available_mutation_parameters)

        if resource.update(update_by)
          render json: serializer(resource)
        else
          errors = resource.errors.full_messages
          render json: errors, status: :forbidden
        end

      else
        raise UnauthorizedError.new('Not allowed')
      end
    end
  end

  def destroy
    process_resource do |resource|
      if permissions.destroy credential: credential, resource: resource
        resource.destroy

        if resource.destroyed?
          render json: { success: true }
        else
          errors = resource.errors.full_messages
          render json: errors, status: :forbidden
        end

      else
        raise UnauthorizedError.new('Not allowed')
      end
    end
  end

  private

  def process_resource
    resource = application_record.find_by(id: params[:id])

    if resource
      yield resource
    else
      raise ActionController::RoutingError.new('Not Found')
    end
  end

  def application_record
    params[:application_record]
  end

  def permissions
    params[:permissions]
  end

  def serializer resource
    params[:serializer].call(resource)
  end

  def available_query_parameters
    params[:available_query_parameters]
  end

  def available_mutation_parameters
    params[:available_mutation_parameters]
  end

  def credential
    params[:credential].call(request)
  end
end
