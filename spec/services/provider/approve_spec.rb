# frozen_string_literal: true

require "rails_helper"

RSpec.describe Provider::Approve, backend: true do
  subject(:approve) { described_class.call(approval_request) }

  let(:managers) do
    [
      build(:data_administrator, email: "first@manager.com"),
      build(:data_administrator, email: "second@manager.com")
    ]
  end
  let(:provider) { create(:provider, status: :unpublished, data_administrators: managers) }
  let!(:approval_request) { ApprovalRequest.create!(approvable: provider, user: create(:user), status: :published) }

  context "when the approval request is pending" do
    it "publishes the provider" do
      expect { approve }.to change { provider.reload.status }.from("unpublished").to("published")
    end

    it "reports the approval" do
      expect(approve).to be(true)
    end

    it "notifies the first provider manager" do
      expect { approve }.to have_enqueued_mail(ProviderMailer, :approved).with(provider, "first@manager.com")
    end

    it "notifies the second provider manager" do
      expect { approve }.to have_enqueued_mail(ProviderMailer, :approved).with(provider, "second@manager.com")
    end

    it "sends one email per provider manager" do
      expect { approve }.to have_enqueued_mail(ProviderMailer, :approved).twice
    end
  end

  context "when the accept action is already assigned but not yet saved" do
    before { approval_request.assign_attributes(status: :deleted, current_action: "accepted") }

    it "notifies the provider managers" do
      expect { approve }.to have_enqueued_mail(ProviderMailer, :approved).twice
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
      expect { approve }.to have_enqueued_mail(ProviderMailer, :approved).once
    end
  end

  context "when the approval request has already been accepted" do
    before { approval_request.update_columns(status: "deleted", last_action: "Accept") }

    it "does not notify the provider managers again" do
      expect { approve }.not_to have_enqueued_mail(ProviderMailer, :approved)
    end

    it "reports that nothing was approved" do
      expect(approve).to be(false)
    end
  end

  context "when the approval request was rejected" do
    before { approval_request.update_columns(status: "deleted", last_action: "Reject") }

    it "does not notify the provider managers" do
      expect { approve }.not_to have_enqueued_mail(ProviderMailer, :approved)
    end
  end
end
