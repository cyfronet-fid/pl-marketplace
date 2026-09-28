# frozen_string_literal: true

require "rails_helper"

RSpec.describe Backoffice::ApprovalRequestsController, type: :controller, backend: true do
  describe "PATCH #update" do
    subject(:review) do
      patch :update,
            params: {
              id: approval_request.id,
              approval_request: {
                current_action: current_action,
                message: "Review message"
              }
            },
            format: :turbo_stream
    end

    let(:submitter) { create(:user) }
    let(:provider) do
      create(:provider, status: :unpublished, data_administrators: [build(:data_administrator, email: submitter.email)])
    end
    let(:approval_request) { ApprovalRequest.create!(approvable: provider, user: submitter, status: :published) }

    before { sign_in create(:user, roles: [:coordinator]) }

    context "when the coordinator accepts the provider" do
      let(:current_action) { "accepted" }

      it "publishes the provider" do
        expect { review }.to change { provider.reload.status }.from("unpublished").to("published")
      end

      it "notifies the provider manager that the provider is approved" do
        expect { review }.to have_enqueued_mail(ProviderMailer, :approved).with(provider, submitter.email)
      end
    end

    context "when the coordinator requests changes" do
      let(:current_action) { "requested_for_changes" }

      it "does not send the approval email" do
        expect { review }.not_to have_enqueued_mail(ProviderMailer, :approved)
      end
    end

    context "when the coordinator rejects the provider" do
      let(:current_action) { "rejected" }

      it "does not send the approval email" do
        expect { review }.not_to have_enqueued_mail(ProviderMailer, :approved)
      end
    end
  end
end
