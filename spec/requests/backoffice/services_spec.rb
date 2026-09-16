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

    context "when deleting a draft service" do
      let(:service) { create(:service, status: :draft) }

      before { delete backoffice_service_path(service) }

      it "deletes the service" do
        expect(service.reload.status).to eq "deleted"
      end
    end

    context "when publishing a draft service" do
      let(:service) { create(:service, status: :draft) }

      before { post backoffice_service_publish_path(service) }

      it "publishes the service" do
        expect(service.reload).to be_published
      end
    end

    context "when changing a published service to unpublished" do
      let(:service) { create(:service, status: :published) }

      before { post backoffice_service_draft_path(service) }

      it "changes the service to unpublished" do
        expect(service.reload).to be_unpublished
      end
    end

    context "when publishing a deleted service" do
      let(:service) { create(:service, status: :deleted) }

      before { post backoffice_service_publish_path(service) }

      it "redirects to the root page" do
        expect(response).to redirect_to(root_path(anchor: ""))
      end

      it "sets the authorization alert" do
        expect(flash[:alert]).to eq(I18n.t("default", scope: :pundit))
      end
    end

    context "when changing a deleted service to unpublished" do
      let(:service) { create(:service, status: :deleted) }

      before { post backoffice_service_draft_path(service) }

      it "redirects to the root page" do
        expect(response).to redirect_to(root_path(anchor: ""))
      end

      it "sets the authorization alert" do
        expect(flash[:alert]).to eq(I18n.t("default", scope: :pundit))
      end
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
