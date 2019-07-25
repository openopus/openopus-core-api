# install_generator.rb: -*- Ruby -*-  DESCRIPTIVE TEXT.
# 
#  Copyright (c) 2019 Brian J. Fox Opus Logica, Inc.
#  Author: Brian J. Fox (bfox@opuslogica.com)
#  Birthdate: Sun Jul 21 12:11:14 2019.
require 'generators/openopus/core/api/helpers'

module Openopus
  module Core
    module Api
      module Generators
        class InstallGenerator < Rails::Generators::Base
          include Openopus::Core::Api::Generators::Helpers

          source_root File.expand_path("../templates", __FILE__)

          desc "Mounts Core API into a rails app."

          def create_initializer
            template "initializer.rb", File.join('config','initializers','openopus_core_api.rb')
          end

          def mount_engine
            inject_into_file routes_path, :after => ".routes.draw do\n" do
              "  mount Openopus::Core::Api::Engine => '/api/v1' \n"
            end
          end

        end
      end
    end
  end
end
