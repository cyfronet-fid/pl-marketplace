# frozen_string_literal: true

class Provider::RequestChanges < Provider::ApprovalDecision
  def initialize(approval_request, message)
    super(approval_request)
    @message = message
  end

  def call
    return false unless pending_decision? && @approval_request.valid?
    return false unless @message.persisted? || Message::Create.call(@message)
    return false unless Provider::Unpublish.call(@provider)

    notify_managers { |email| ProviderMailer.changes_requested(@message, email) }
    true
  end
end
