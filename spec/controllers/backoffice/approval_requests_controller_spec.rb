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

      it "stores the coordinator message once" do
        expect { review }.to change(approval_request.messages, :count).by(1)
      end

      it "keeps the message unedited" do
        review
        expect(approval_request.messages.last).not_to be_edited
      end

      it "keeps the approval request open" do
        expect { review }.not_to(change { approval_request.reload.status }.from("published"))
      end

      it "notifies the provider manager with the coordinator message" do
        expect { review }.to have_enqueued_mail(ProviderMailer, :changes_requested).with(
          having_attributes(message: "Review message"),
          submitter.email
        )
      end

      it "does not send the approval email" do
        expect { review }.not_to have_enqueued_mail(ProviderMailer, :approved)
      end

      it "does not send the rejection email" do
        expect { review }.not_to have_enqueued_mail(ProviderMailer, :rejected)
      end
    end

    context "when the coordinator requests changes without a message" do
      subject(:review) do
        patch :update,
              params: {
                id: approval_request.id,
                approval_request: {
                  current_action: "requested_for_changes",
                  message: ""
                }
              }
      end

      it "does not send the changes requested email" do
        expect { review }.not_to have_enqueued_mail(ProviderMailer, :changes_requested)
      end
    end

    context "when the coordinator only sends a message" do
      let(:current_action) { "" }

      it "does not send the changes requested email" do
        expect { review }.not_to have_enqueued_mail(ProviderMailer, :changes_requested)
      end
    end

    context "when the coordinator rejects the provider" do
      let(:current_action) { "rejected" }

      it "keeps the provider unpublished" do
        expect { review }.not_to(change { provider.reload.status }.from("unpublished"))
      end

      it "closes the approval request" do
        expect { review }.to change { approval_request.reload.status }.from("published").to("deleted")
      end

      it "notifies the provider manager that the provider was not approved" do
        expect { review }.to have_enqueued_mail(ProviderMailer, :rejected).with(provider, submitter.email)
      end

      it "does not send the approval email" do
        expect { review }.not_to have_enqueued_mail(ProviderMailer, :approved)
      end
    end

    context "when the coordinator rejects an already rejected provider" do
      let(:current_action) { "rejected" }

      before { approval_request.update_columns(status: "deleted", last_action: "Reject") }

      it "does not send the rejection email again" do
        expect { review }.not_to have_enqueued_mail(ProviderMailer, :rejected)
      end
    end
  end
end
