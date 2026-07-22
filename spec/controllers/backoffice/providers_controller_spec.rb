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
      get :index, flash: { provider_approval_modal: true }

      expect(Capybara.string(response.body)).to have_css("#provider-approval-modal")
      expect(flash[:provider_approval_modal]).to be_nil
    end

    it "preserves the profile-completion follow-up for other provider creations" do
      provider = create(:provider)

      get :index, flash: { provider_profile_completion: provider.id }

      expect(Capybara.string(response.body)).to have_css("#provider-profile-completion-modal")
      expect(response.body).to include(backoffice_provider_path(provider))
      expect(flash[:provider_profile_completion]).to be_nil
    end
  end
end
