# frozen_string_literal: true

class ProviderMailer < ApplicationMailer
  def new_question(recipient_email, author, email, text, provider)
    @provider = provider
    @message = text
    @author = author
    @email = email

    mail(to: recipient_email, subject: "Question about #{@provider.name}", template_name: "new_question")
  end

  # ONB-01
  def waiting_for_approval(approval_request)
    @provider = approval_request.approvable
    @user = approval_request.user

    mail(
      to: @user.email,
      subject: "New provider - #{@provider.name} is waiting for approval"
    )
  end
end
