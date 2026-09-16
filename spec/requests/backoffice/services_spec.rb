# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Backoffice service", backend: true do
  include OmniauthHelper
  include ExternalServiceDataHelper

  context "when logged in as a service portfolio manager" do
    let(:user) { create(:user, roles: [:coordinator]) }

    before { login_as(user) }

    context "when accessing Backoffice services" do
      before { get backoffice_services_path }

      it "allows access" do
        expect(response).to have_http_status(:ok)
      end
    end

    it "deletes services" do
      service = create(:service, status: :draft)

      delete backoffice_service_path(service)

      expect(service.reload.status).to eq "deleted"
    end

    it "publishes draft services" do
      service = create(:service, status: :draft)

      post backoffice_service_publish_path(service)

      expect(service.reload).to be_published
    end

    it "changes published services to unpublished" do
      service = create(:service, status: :published)

      post backoffice_service_draft_path(service)

      expect(service.reload).to be_unpublished
    end

    it "redirects to the root page when publishing a deleted service" do
      service = create(:service, status: :deleted)

      post backoffice_service_publish_path(service)

      expect(response).to redirect_to(root_path(anchor: ""))
    end

    it "sets the authorization alert when publishing a deleted service" do
      service = create(:service, status: :deleted)

      post backoffice_service_publish_path(service)

      expect(flash[:alert]).to eq(I18n.t("default", scope: :pundit))
    end

    it "redirects to the root page when changing a deleted service status" do
      service = create(:service, status: :deleted)

      post backoffice_service_draft_path(service)

      expect(response).to redirect_to(root_path(anchor: ""))
    end

    it "sets the authorization alert when changing a deleted service status" do
      service = create(:service, status: :deleted)

      post backoffice_service_draft_path(service)

      expect(flash[:alert]).to eq(I18n.t("default", scope: :pundit))
    end
  end

  context "when logged in without Backoffice permissions" do
    let(:user) { create(:user) }

    before do
      login_as(user)
      get backoffice_services_path
    end

    it "redirects to the root page" do
      expect(response).to redirect_to(root_path(anchor: ""))
    end

    it "sets the authorization alert" do
      expect(flash[:alert]).to eq(I18n.t("default", scope: :pundit))
    end
  end
end
