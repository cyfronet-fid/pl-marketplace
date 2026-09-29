# frozen_string_literal: true

require "rails_helper"

RSpec.describe Provider::RequestChanges, backend: true do
  subject(:request_changes) { described_class.call(approval_request, message) }

  let(:managers) do
    [
      build(:data_administrator, email: "first@manager.com"),
      build(:data_administrator, email: "second@manager.com")
    ]
  end
  let(:submitter) { create(:user) }
  let(:provider) { create(:provider, status: :unpublished, data_administrators: managers) }
  let!(:approval_request) { ApprovalRequest.create!(approvable: provider, user: submitter, status: :published) }
  let(:message) do
    Message.create!(
      message: "Please add a logo.",
      author: create(:user, roles: [:coordinator]),
      author_role: :mediator,
      scope: :user_direct,
      messageable: approval_request
    )
  end

  context "when the approval request is pending" do
    it "keeps the provider unpublished" do
      expect { request_changes }.not_to(change { provider.reload.status }.from("unpublished"))
    end

    it "reports the request" do
      expect(request_changes).to be(true)
    end

    it "notifies the first provider manager with the coordinator message" do
      expect { request_changes }.to have_enqueued_mail(ProviderMailer, :changes_requested).with(
        message,
        "first@manager.com"
      )
    end

    it "notifies the second provider manager" do
      expect { request_changes }.to have_enqueued_mail(ProviderMailer, :changes_requested).with(
        message,
        "second@manager.com"
      )
    end

    it "sends one email per provider manager" do
      expect { request_changes }.to have_enqueued_mail(ProviderMailer, :changes_requested).twice
    end
  end

  context "when changes were already requested before" do
    before { approval_request.update_columns(last_action: "Request for completion") }

    it "treats the new request as a new notification" do
      expect { request_changes }.to have_enqueued_mail(ProviderMailer, :changes_requested).twice
    end
  end

  context "when the submitter is a coordinator" do
    let(:submitter) { create(:user, roles: [:coordinator]) }

    it "notifies the provider managers" do
      expect { request_changes }.to have_enqueued_mail(ProviderMailer, :changes_requested).twice
    end
  end

  context "when provider managers share an email address" do
    let(:managers) do
      [
        build(:data_administrator, email: "shared@manager.com"),
        build(:data_administrator, email: "SHARED@manager.com")
      ]
    end

    it "notifies the address once" do
      expect { request_changes }.to have_enqueued_mail(ProviderMailer, :changes_requested).once
    end
  end

  context "when the approval request is already closed" do
    before { approval_request.update_columns(status: "deleted", last_action: "Reject") }

    it "does not notify the provider managers" do
      expect { request_changes }.not_to have_enqueued_mail(ProviderMailer, :changes_requested)
    end

    it "reports that nothing was requested" do
      expect(request_changes).to be(false)
    end
  end
end
