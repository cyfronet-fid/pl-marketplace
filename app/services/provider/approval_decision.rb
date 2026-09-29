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
      manager_users.each { |user| build_mail.call(user.email).deliver_later }
    end
  end

  # Only managers linked to a Marketplace account (see DataAdministrator#connect_user) are notified.
  def manager_users
    User.where(id: @provider.data_administrators.select(:user_id))
  end
end
