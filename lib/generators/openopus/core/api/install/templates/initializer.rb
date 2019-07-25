# initializer.rb: -*- Ruby -*-  DESCRIPTIVE TEXT.
# 
#  Copyright (c) 2019 Brian J. Fox Opus Logica, Inc.
#  Author: Brian J. Fox (bfox@opuslogica.com)
#  Birthdate: Sun Jul 21 12:19:34 2019.
Openopus::Core::Api.config do |config|
  # authorize_with specifies the block to use to determine whether
  # a certain user is authorized to perform an action on a
  # resource.
  # - user is whatever authenication returned.
  # - action is a symbol that is :index, :read, :create, :update, :destroy.
  # - resource is an individual model or the model's class if a collection.
  config.authorize_with do |user, action, resource|
    # allowed = false
    # allowed = true if action == :create and resource == Person
    # allowed = true if action == :read and resource.class == Person and resource.id == 1
    # Rails.logger.debug("user = '#{user}' -- action = '#{action} -- resource-type = '#{resource.class.to_s}' -- resource = '#{resource}'")
    # allowed
    true
  end
end
