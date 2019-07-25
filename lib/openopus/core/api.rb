require "openopus/core/api/version"
require "openopus/core/api/engine"
require "openopus/core/api/config"

module Openopus
  module Core
    module Api
      def self.config(&block)
        if block
          block.call(Openopus::Core::Api::Config)
        else
          Openopus::Core::Api::Config
        end
      end
      class User
        attr_accessor :username
        def initialize(username)
          self.username = username
        end
      end
      class Defaults
        def authenticate_request(request, params)
          return User.new("anonymous")
        end
      end
    end
  end
end
