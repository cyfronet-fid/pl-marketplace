# frozen_string_literal: true

class ApplicationMailer < ActionMailer::Base
  LOGO_NAME = "eoscpl-logo.png"
  LOGO_PATH = Rails.root.join("app/assets/images/eoscpl-email-logo.png")

  default from: ENV.fetch("FROM_EMAIL", "EOSC PL <eosc-noreply@eosc.pl>")
  layout "mailer"
  
  helper MailerHelper

  before_action :attach_logo

  private

  # Embedded in the email, so the logo shows without an asset host.
  def attach_logo
    attachments.inline[LOGO_NAME] = File.binread(LOGO_PATH)
  end
end
