# frozen_string_literal: true

class Provider::Approve < Provider::ApplicationService
  def initialize(approval_request)
    super(approval_request.approvable)
    @approval_request = approval_request
  end

  def call
    return false unless pending_approval?
    return false unless Provider::Publish.call(@provider)

    notify_managers
    true
  end

  private

  # Reads the persisted state, as the caller may already have assigned the new action to the request.
  def pending_approval?
    @approval_request.status_in_database != "deleted" && @approval_request.last_action_in_database != "accepted"
  end

  def notify_managers
    manager_emails.each { |email| ProviderMailer.approved(@provider, email).deliver_later }
  end

  def manager_emails
    @provider.data_administrators.map(&:email).compact_blank.uniq(&:downcase)
  end
end
