# frozen_string_literal: true

class Provider::ApprovalDecision < Provider::ApplicationService
  CLOSING_ACTIONS = %w[accepted rejected].freeze

  def initialize(approval_request, message = nil)
    super(approval_request.approvable)

    @approval_request = approval_request
    @message = message
  end

  private

  def pending_decision?
    @approval_request.status_in_database != "deleted" &&
      CLOSING_ACTIONS.exclude?(@approval_request.last_action_in_database)
  end

  # Emails go out only once the surrounding transaction commits, and never after a rollback.
  def notify_managers(&build_mail)
    ActiveRecord.after_all_transactions_commit do
      manager_emails.each { |email| build_mail.call(email).deliver_later }
    end
  end

  def manager_emails
    @provider.data_administrators.map(&:email).compact_blank.uniq(&:downcase)
  end
end
