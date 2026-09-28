# frozen_string_literal: true

require "rails_helper"

RSpec.describe Backoffice::ProvidersController, type: :controller, backend: true do
  render_views

  let(:user) { create(:user, roles: [:coordinator]) }

  before { sign_in user }

  describe "GET #index" do
    it "does not render approval guidance without the one-time flag" do
      get :index

      expect(response).to have_http_status(:ok)
      expect(Capybara.string(response.body)).not_to have_css("#provider-approval-modal")
    end

    it "renders and consumes the approval-guidance flag" do
      get :index, session: { provider_approval_modal: true }

      expect(Capybara.string(response.body)).to have_css("#provider-approval-modal")
      expect(session[:provider_approval_modal]).to be_nil
    end

    it "preserves the profile-completion follow-up for other provider creations" do
      provider = create(:provider)

      get :index, session: { provider_profile_completion: provider.id }

      expect(Capybara.string(response.body)).to have_css("#provider-profile-completion-modal")
      expect(response.body).to include(backoffice_provider_path(provider))
      expect(session[:provider_profile_completion]).to be_nil
    end
  end

  describe "PATCH #update" do
    subject(:update_provider) do
      patch :update,
            params: {
              id: provider.to_param,
              provider: {
                name: "Renamed provider",
                upstream_id: ""
              }
            },
            format: :turbo_stream
    end

    context "when the provider is already approved" do
      let(:provider) { create(:provider, status: :published) }

      before do
        ApprovalRequest.create!(
          approvable: provider,
          user: create(:user),
          status: :deleted,
          last_action: :accepted
        )
      end

      it "updates the provider" do
        expect { update_provider }.to change { provider.reload.name }.to("Renamed provider")
      end

      it "does not send the approval email again" do
        expect { update_provider }.not_to have_enqueued_mail(ProviderMailer, :approved)
      end
    end
  end
end
