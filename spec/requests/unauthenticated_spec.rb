# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Unauthenticated user", backend: true do
  include OmniauthHelper

  it "should be redirected to checkin" do
    get profile_path

    expect(response).to redirect_to(user_checkin_omniauth_authorize_path)
  end

  it "should not be redirected if accessing root_path" do
    get root_path

    expect(response.status).to eq(200)
  end

  it "should be redirected to checkin when accessing backoffice services" do
    get backoffice_services_path

    expect(response).to redirect_to(user_checkin_omniauth_authorize_path)
  end

  it "should return to backoffice services after successful checkin" do
    user = create(:user, roles: [:coordinator])
    stub_checkin(user)

    get backoffice_services_path
    expect(response).to redirect_to(user_checkin_omniauth_authorize_path)
    expect(request.session["user_return_to"]).to eq(backoffice_services_path)

    get user_checkin_omniauth_authorize_path
    expect(response).to redirect_to(user_checkin_omniauth_callback_path)

    follow_redirect!
    expect(response).to redirect_to(backoffice_services_path)
    expect(request.session["user_return_to"]).to be_nil

    follow_redirect!
    expect(response).to have_http_status(:ok)
  end
end
