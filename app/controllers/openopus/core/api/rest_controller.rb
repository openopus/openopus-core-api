# rest_controller.rb: -*- Ruby -*-  DESCRIPTIVE TEXT.
# 
# Copyright (c) 2019 Brian J. Fox Opus Logica, Inc.
# Author: Dan Staudigel (dstaudigel@gmail.com) and Brian J. Fox (bfox@opuslogica.com)
# Second Birthdate: Sun Jul 21 12:53:50 2019.
#
# This controller provides basic REST operations on any given
# model.  Model-specific assignment behavior can be customized by
# overriding the assign_attributes in that model.  View/JSON
# customization can be done using the as_api_json function, or the
# as_json function, but this doesn't have the ideal level of
# flexibility.  For example, how would one render a record with
# limited fields for collection views and more comprehensive rows for
# individual retrieval?  This customization is done using view-level
# rendering.  Here is the process by which view paths/partials are
# selected:
#
# Collection-like requests:
#  - multiple-row-requests (/api/v1/people?ids=34,23,2)
#    - renders /openopus/core/api/people/people with @people = [34,23,2] and @collection = false
#      - by default will render /openopus/core/api/people/person, with person and @collection = false 
#        for each row
#  - collection requests (/api/v1/people?group_id=18)
#    - renders /openopus/core/api/people/people with @people = [...] and @collection = true
#      - by default will render /openopus/core/api/people/_person with person and @collection = true
#
# Single-row requests:
#  - render /openopus/core/api/people/person with person and @collection = false
#    - by default will render /openopus/core/api/people/_person with person and @collection = false;
# 

module Openopus
  module Core
    module Api
      class RestController < BaseController
        before_action :setup
        before_action :model
        
        API = "openopus/core/api"

        def plural_template_name
          @tmpl_plural ||= singular_template_name.pluralize
        end

        def singular_template_name
          @tmpl_name ||= @model.name.underscore
        end
        
        def render_many(rows, is_collection=false)
          @is_collection = is_collection
          
          if template_exists?(tmpl="#{API}/#{ model.new.to_partial_path.pluralize }")
            locals = {}
            locals[@model.model_name.element.pluralize] = rows
            render(tmpl, locals: locals)
            true
          elsif template_exists?(tmpl="#{API}/base/collection")
            render(tmpl, locals: { collection: rows })
            true
          else
            false
          end
        end

        def render_one(row)
          @is_collection = false
          if template_exists?(tmpl="#{API}/#{ row.to_partial_path }")
            locals = {}
            locals[model.model_name.element.to_sym] = row
            render(tmpl, locals: locals)
            true
          elsif template_exists?(tmpl="#{API}/base/item")
            render(tmpl, locals: { item: row })
            true
          else
            false
          end
        end

        def render_one_json(m)
          include = m.class.reflect_on_all_associations.select do 
            |a| a.macro == :has_and_belongs_to_many or a.macro == :has_one
          end.map do |a|
            h = {}
            h[a.name] = { only: [:id] }
            h
          end.inject({}) do |a,b|
            a.merge b
          end 

          include = include.merge @include if @include

          options = { authenticated: @authenticated, include: include }
          options[:deep] = true if @deep
          if m.respond_to?(:as_api_json)
            h = m.as_api_json(options)
          else
            options[:for_api] = true
            h = m.as_json(options)
          end
          (h[:errors] = m.errors.messages if not m.errors.messages.blank?) rescue nil
          h
        end
        
        def render_json(data)
          @count = data.count if data.respond_to?(:count)
          
          data = data.limit(@limit) if @limit
          data = data.offset(@offset) if @offset

          @collection = data

          if data.respond_to?(:collect)
            return if render_many(data, true)

            meta = {}
            begin
              if defined? @count
                meta[:total] = @count
              end
            rescue
              # Error occurred trying to get count, instead of stopping
              # request, send down the total number in the request
              meta[:total] = data.length
            end

            meta = data.collect { |m| render_one_json(m) }
            render(json: meta)
          else
            return if render_one(data)
            render(json: render_one_json(data))
          end
        end

        def setup
          @rest = params[:rest]
          @action = params[:action]
          @controller = self
          @request = request

          @limit = params[:limit]
          @offset = params[:offset]
          @deep = params[:deep]
        end

        def model
          namespace ||= params[:namespace].camelize if params.has_key?(:namespace)
          model_name ||= params[:model].singularize.camelize if params.has_key?(:model)
          if namespace
            qualified_name = "#{namespace}::#{model_name}" 
          elsif model_name
            qualified_name = model_name
          else
            parts = self.class.name.split("::").from(1)
            parts[parts.length-1] = parts[parts.length-1].gsub('Controller','').singularize
            qualified_name = parts.join('::')
          end

          @model   = qualified_name.safe_constantize
          @model ||= params[:model].camelize.safe_constantize
          @model
        end

        def default_scope
          model
        end

        def id_list
          ids = params[:ids].split(',')
          @instances = default_scope.where(id: ids)
          
          render_error(ApiError::UNAUTHORIZED) and return false unless authorized?(:read, @instances)

          return if render_many(@instances, false)
          render_json(@instances)
        end
        
        def index
          query_begin = nil

          if params[:ids]
            id_list
          else
            search_hash = {}
            do_search = false
            special_handler = false

            @instances = nil

            params.each do |key, value|
              unless special_handler
                special_handler ||= Openopus::Core::Api.config.search_for(@model, key)
                special_handler ||= Openopus::Core::Api.config.search_for(@model, key.to_sym)
                @instances = instance_exec(value, &special_handler) if special_handler
              end
            end

            unless special_handler
              column_syms = model.columns.collect {|c| c.name.to_sym}
              params.each do |key, val|
                if column_syms.include?(key.to_sym)
                  search_hash[key.to_sym] = val
                  do_search = true
                elsif /.*_id$/.match(key.to_s)
                  # This is an ID column, but our model doesn't "belong_to" this thing. So,
                  # this thing must belong to us, whether through a join table or not.  Thus,
                  #
                  #       GET /api/v1//addresses?person_id=12
                  #
                  # means, Person.find(12).addressess...
                  # 
                  other_model = (key.to_s.gsub(/_id$/, "").camelize.safe_constantize).new.class rescue nil
                  begin
                    query_begin = (other_model.unscoped.find(val)).send(@model.name.tableize.to_sym) if other_model
                  rescue ActiveRecord::RecordNotFound
                    Rails.logger.info("API: Error finding the requested #{other_model.name}: #{val}")
                    render_error(ApiError::UNAUTHORIZED) and return false
                  end
                end
              end
            end

            query_begin ||= default_scope
            if do_search
              @instances = query_begin.where(search_hash)
              render_error(ApiError::UNAUTHORIZED) and return false unless authorized?(:read, @instances)
            elsif special_handler
              render_error(ApiError::UNAUTHORIZED) and return false unless authorized?(:read, @instances)
            else
              render_error(ApiError::UNAUTHORIZED) and return false unless authorized?(:index, model)
              @instances = query_begin.all
            end
            
            @include = JSON.parse(params[:include]) rescue {}

            render_json(@instances)
          end
        end

        def show
          read
        end
        
        def read
          # Use find, but rescue away from a 404 exception, we need to
          # render a 403 if the person isn't allowed to see that there
          # isn't an item there.
          @instance = (@model.unscoped.find(params[:id]) rescue nil)
          
          # If there is no model and the user doesn't have indexing
          # privileges, we can't report to them that there isn't a model
          # there, so we render this error;
          render_error(ApiError::UNAUTHORIZED) and return false if !@instance && !authorized?(:index,model)

          # However, if the user is allowed to see any item in this collection
          # (indexing privileges), and the item isn't there, we need to
          # report it as a 404:
          raise ActiveRecord::RecordNotFound and return false unless @instance
          
          @include = JSON.parse(params[:include]) rescue {}

          render_error(ApiError::UNAUTHORIZED) and return false unless authorized?(:read, @instance)

          render_json(@instance)
        end

        def create
          hash = JSON.parse(request.raw_post) rescue nil
          hash ||= params
          @instance = model.new()

          hash.delete(:controller) if hash.has_key?(:controller)
          hash.delete(:action) if hash.has_key?(:action)
          hash.delete(:model) if hash.has_key?(:model)
          hash.delete(:base) if hash.has_key?(:base)
          hash.delete(:format) if hash.has_key?(:format)

          # params.require(:rest).permit(params[:rest].keys.collect { |k| k.to_sym })

          assign_instance_attributes(hash.to_h)

          render_error(ApiError::UNAUTHORIZED) and return false unless authorized?(:create, @instance)
          @instance.save
          
          render_json(@instance)
        end

        def assign_instance_attributes(hash)
          @instance.assign_attributes(hash)
        end

        def update
          @instance = @model.unscoped.find(params[:id])

          # BYPASS THE BLOODY STRONG PARAMETERS.
          hash = request.params
          hash = hash.to_hash.with_indifferent_access
          hash.delete(:controller) if hash.has_key?(:controller)
          hash.delete(:action) if hash.has_key?(:action)
          hash.delete(:model) if hash.has_key?(:model)
          hash.delete(:id) if hash.has_key?(:id)

          assignable = {}
          hash.keys.each { |k| assignable[k] = hash[k] if @instance.respond_to?((k.to_s + "=").to_sym) }
          assign_instance_attributes(assignable)

          render_error(ApiError::UNAUTHORIZED) and return false unless authorized?(:update, @instance)

          @instance.save

          render_json(@instance)
        end

        def destroy
          if params[:id]
            @instance = model.unscoped.find(params[:id])
            render_error(ApiError::UNAUTHORIZED) and return false unless authorized?(:destroy, @instance)
            @instance.destroy!
          elsif params[:ids]
            ids = params[:ids].split(",")
            ids.each do |id|
              @instance = model.unscoped.find(id)
              render_error(ApiError::UNAUTHORIZED) and return false unless authorized?(:destroy, @instance)
              @instance.destroy!
            end
          end
          
          render(json: { success: true })
        end
      end
    end
  end
end
