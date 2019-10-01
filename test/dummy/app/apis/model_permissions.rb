module ModelPermissions
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
end
