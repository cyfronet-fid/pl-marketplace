# frozen_string_literal: true

module OrderingApi
  class AddProviderOMS
    def initialize(oms_name, provider_pid, authentication_token)
      @oms_name = oms_name.underscore
      @provider_pid = provider_pid
      @authentication_token = authentication_token
    end

    def call
      provider = Provider.find_by(pid: @provider_pid)
      if provider.blank?
        logger.info "Provider with pid '#{@provider_pid}' not found. It must exist to attach the OMS to it."
        return
      end

      admin = find_admin || initialize_admin
      admin.authentication_token = @authentication_token if @authentication_token.present?
      admin.save!

      oms = OMS.find_or_initialize_by(name: "#{@oms_name.titlecase} OMS")
      oms.type = :provider_group
      append_if_not_present oms.providers, provider
      append_if_not_present oms.administrators, admin
      oms.save!

      logger.info "OMS id: #{oms.id}, name: '#{oms.name}', providers: #{oms.providers.pluck(:pid).join(", ")}"
      logger.info "Admin user uid: '#{admin_uid}', token: '#{admin.authentication_token}'"
    end

    private

    def admin_uid
      "iama#{@oms_name}admin"
    end

    def find_admin
      UserIdentity.find_by(provider: "checkin", uid: admin_uid)&.user
    end

    def initialize_admin
      user = User.new(first_name: @oms_name.titlecase, last_name: "admin", email: "#{@oms_name}_admin@example.com")
      user.identities.build(provider: "checkin", uid: admin_uid, primary: true)
      
      user
    end

    def append_if_not_present(association, element)
      association << element if association.exclude?(element)
    end

    def logger
      Rails.logger
    end
  end
end
