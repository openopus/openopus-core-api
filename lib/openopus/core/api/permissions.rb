module Openopus
  module Core
    module Api
      module Permissions
        class BasePermissions
          def self.destroy credential:, resources:
                                    # destroy and delete are interchangeable terms
                                    self.delete credential: credential, resources: resources
          end
        end

        class OpenPermissions < BasePermissions
          def self.create credential:, resource:
                                   true
          end

          def self.read credential:, resource:
                                 true
          end

          def self.update credential:, resource:
                                   true
          end

          def self.delete credential:, resource:
                                   true
          end
        end


        class ClosedPermissions < BasePermissions
          def self.create credential:, resource:
                                   false
          end

          def self.read credential:, resource:
                                 false
          end

          def self.update credential:, resource:
                                   false
          end

          def self.delete credential:, resource:
                                         false
          end
        end
      end
    end
  end
end
