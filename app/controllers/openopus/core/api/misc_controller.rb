# misc_controller.rb: -*- Ruby -*-  DESCRIPTIVE TEXT.
# 
#  Copyright (c) 2019 Brian J. Fox Opus Logica, Inc.
#  Author: Brian J. Fox (bfox@opuslogica.com)
#  Birthdate: Thu Jul 25 13:25:08 2019.
module Openopus
  module Core
    module Api
      class MiscController < BaseController
        def version
          render json: { version: "v1" }
        end

        def whoami
          render json: (@authenticated ? @authenticated : { error: "Nobody!" })
        end
      end
    end
  end
end
