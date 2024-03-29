# config.rb: -*- Ruby -*-  DESCRIPTIVE TEXT.
# 
#  Copyright (c) 2019 Brian J. Fox Opus Logica, Inc.
#  Author: Brian J. Fox (bfox@opuslogica.com)
#  Birthdate: Sun Jul 21 12:03:31 2019.
module Openopus
  module Core
    module Api
      module Config
        DEFAULT_ERROR_TRANSFORM = proc { |hash| hash }

        class << self

          # token_name is the name that you wish to use to pass the
          # token back and forth to your server.  By default the tag
          # is 'oo-api-token'.  This name can either appear as a
          # passed parameter, or as an HTTP header.
          mattr_accessor :token_name

          # request_authenticator contains the actual method to
          # call in order to authenticate the incoming request.  The
          # method called will be passed a hash containing :request
          # and :params, which are the controller request and params
          # objects.  The called method should return an object that
          # represents the authenticated user.
          mattr_accessor :request_authenticator

          # authorize_with specifies the block to use to determine whether
          # a certain user is authorized to perform an action on a
          # resource.  The block should be of the form:
          # config.authorize_with do |user,action,resource|
          #
          # - user is whatever authorize_with returns
          # - action is a symbol that is :index, :read, :create, :update, :destroy
          # - resource is an individual model or collection 
          def authorize_with(&blk)
            @authorize_with = blk if blk
            @authorize_with
          end

          # transform_error_with allows you to be more specific with
          # how API errors are displayed to the user, by default just the
          # description is sent to the user with an HTTP status code.
          def transform_error_with(&blk)
            @transform_error_with = blk if blk
            @transform_error_with || DEFAULT_ERROR_TRANSFORM
          end

          # Here are some pieces of configuration that allow for the
          # definition of special-case search terms.  Using these, you can
          # specify an API route like:
          #
          # /api/widgets?wodget_ids=8,6,2
          #
          # using the call:
          #
          # config.search_for Widget, :wodget_ids do |wodget_ids|
          #   Widget.search_using_wodgets(Wodget.where(id: wodget_ids.split(',')))
          # end
          def search_for(model, symbol, &blk)
            @search_helpers ||= Hash.new
            model_specific = @search_helpers[model.to_s] ||= Hash.new

            model_specific[symbol] = blk if blk
            model_specific[symbol]
          end

          # Configuration for setting up how API tokens are delivered to
          # new users.  By default OCA "reuses" API tokens per-user,
          # issuing only one API token to each user until they sign out
          # that one session.  This causes a logout on one browser/session to
          # log out all other sessions.  You can also configure it to issue a
          # new API token for every login event.
          def new_api_token_every_login(boolean=nil)
            if @new_api_token_every_login == nil && boolean!=nil
              @new_api_token_every_login = boolean
            end
            @new_api_token_every_login || false
          end
        end
      end
    end
  end
end
