# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Unauthenticated user", backend: true do
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
  end
end
