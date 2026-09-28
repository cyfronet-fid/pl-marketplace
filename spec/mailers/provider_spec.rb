# frozen_string_literal: true

require "rails_helper"

RSpec.describe ProviderMailer, type: :mailer, backend: true do
  describe "#waiting_for_approval" do
    subject(:mail) { described_class.waiting_for_approval(approval_request) }

    let(:user) { create(:user) }
    let(:provider) { create(:provider, name: "Awesome provider", status: :unpublished) }
    let(:approval_request) { ApprovalRequest.create!(approvable: provider, user: user, status: :published) }
    let(:html_body) { Capybara.string(mail.html_part.body.decoded) }
    let(:provider_url) do
      Rails.application.routes.url_helpers.backoffice_provider_url(provider, host: "localhost:3000")
    end

    it "is sent to the submitting user" do
      expect(mail.to).to contain_exactly(user.email)
    end

    it "has the provider name in the subject" do
      expect(mail.subject).to eq("New provider - Awesome provider is waiting for approval")
    end

    it "thanks the user for submitting the provider" do
      expect(html_body).to have_content(/Thanks for submitting\s+Awesome provider\.\s+Our team will review it\./)
    end

    it "explains when resources can be published" do
      expect(html_body).to have_content(
        "You can add resources now, but you can publish them only after the provider is approved."
      )
    end

    it "links the View provider button to the provider page" do
      expect(html_body).to have_link("View provider", href: provider_url)
    end

    it "includes the provider page link in the text part" do
      expect(mail.text_part.body.decoded).to include(provider_url)
    end
  end
end
