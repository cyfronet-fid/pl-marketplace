# frozen_string_literal: true

module OrderingApi
  class AddSombo
    SOMBO_ADMIN_UID = "iamasomboadmin"

    def call
      sombo_admin = find_sombo_admin || create_sombo_admin
      sombo_admin.update!(roles_mask: 7)

      sombo =
        OMS
          .default_scoped
          .find_or_create_by(name: "SOMBO") do |oms|
            oms.type = :global
            oms.default = true
            oms.custom_params = { order_target: { mandatory: false } }
          end

      sombo.administrators << sombo_admin unless sombo.administrators.include?(sombo_admin)
    end

    private

    def find_sombo_admin
      UserIdentity.find_by(provider: "checkin", uid: SOMBO_ADMIN_UID)&.user
    end

    def create_sombo_admin
      user = User.new(first_name: "SOMBO admin", last_name: "SOMBO admin", email: "sombo@sombo.com", roles_mask: 7)
      user.identities.build(provider: "checkin", uid: SOMBO_ADMIN_UID, primary: true)

      user if user.save
    end
  end
end
