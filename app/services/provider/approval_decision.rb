# frozen_string_literal: true

class Provider::ApprovalDecision < Provider::ApplicationService
  DECIDED_ACTIONS = %w[accepted rejected].freeze

  def initialize(approval_request)
    super(approval_request.approvable)
    @approval_request = approval_request
  end

  private

  # Reads the persisted state, as the caller may already have assigned the new action to the request.
  def pending_decision?
    @approval_request.status_in_database != "deleted" &&
      DECIDED_ACTIONS.exclude?(@approval_request.last_action_in_database)
  end

  def notify_managers
    manager_emails.each { |email| yield(email).deliver_later }
  end

  def manager_emails
    @provider.data_administrators.map(&:email).compact_blank.uniq(&:downcase)
  end
end
