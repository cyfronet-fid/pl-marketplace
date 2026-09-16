# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Unauthenticated user", backend: true do
  include OmniauthHelper

  context "when accessing a protected profile page" do
    before { get profile_path }

    it "redirects to Check-In" do
      expect(response).to redirect_to(user_checkin_omniauth_authorize_path)
    end
  end

  context "when accessing the root page" do
    before { get root_path }

    it "does not require authentication" do
      expect(response).to have_http_status(:ok)
    end
  end

  context "when accessing Backoffice services" do
    before { get backoffice_services_path }

    it "redirects to Check-In" do
      expect(response).to redirect_to(user_checkin_omniauth_authorize_path)
    end

    it "preserves the requested Backoffice page" do
      expect(request.session["user_return_to"]).to eq(backoffice_services_path)
    end

    context "when Check-In authentication is successful" do
      let(:user) { create(:user, roles: [:coordinator]) }

      before do
        stub_checkin(user)
        get user_checkin_omniauth_authorize_path
      end

      it "redirects to the OmniAuth callback" do
        expect(response).to redirect_to(user_checkin_omniauth_callback_path)
      end

      context "when following the Check-In callback" do
        before { follow_redirect! }

        it "redirects to the requested Backoffice page" do
          expect(response).to redirect_to(backoffice_services_path)
        end

        context "when following the Backoffice redirect" do
          before { follow_redirect! }

          it "allows access to Backoffice services" do
            expect(response).to have_http_status(:ok)
          end
        end
      end
    end
  end
end
