# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Backoffice: manage providers", backend: true do
  describe "user logged in service portfolio manager" do
    let(:user) { create(:user, roles: [:coordinator]) }
    let(:provider) { create(:provider) }
    let(:new_params) { { name: "test1111111", abbreviation: "test 111111" } }
    let(:deleted_service) { create(:service, resource_organisation: provider, status: :deleted) }
    let(:errored_service) { create(:service, status: :errored, resource_organisation: provider) }
    let(:draft_service) { create(:service, status: :draft, resource_organisation: provider) }

    before { login_as(user) }

    context "deletes provider" do
      it "without any service" do
        provider
        expect { delete backoffice_provider_path(provider) }.to change {
          Provider.where(status: :deleted).count
        }.by(1)
      end

      it "with all deleted services" do
        deleted_service

        expect { delete backoffice_provider_path(provider) }.to change {
          Provider.where(status: :deleted).count
        }.by(1)
      end

      it "with an errored service" do
        errored_service

        expect { delete backoffice_provider_path(provider) }.to change {
          Provider.where(status: :deleted).count
        }.by(1)
      end

      it "with a draft service" do
        draft_service

        expect { delete backoffice_provider_path(provider) }.to change {
          Provider.where(status: :deleted).count
        }.by(1)
      end
    end

    context 'on update' do
      before do
        put backoffice_provider_path(provider), params: { provider: { upstream_id: nil, **new_params } }
      end

      it "call permitted_attributes with provider with form upstream_id", :aggregate_failures do  
        provider.reload
        expect(provider.upstream_id).to eq(nil)
        new_params.each { |key, value| expect(provider[key]).to eq(value) }
      end
    end

    describe "additional information in provider settings" do
      let(:provider) { create(:provider, status: :published) }
      let(:update_params) { { provider: { current_step: "classification", certifications: ["ISO9001"] } } }
      let(:catalogue) { create(:catalogue, status: :published) }
      context "when provider is invalid" do
        before do
          provider.update_column(:description, "")
          put backoffice_provider_path(provider), params: update_params, as: :turbo_stream
        end
        it "returns success status" do
          expect(response).to have_http_status(:success)
        end

        it "can be saved" do  
          expect(provider.reload.certifications).to eq(["ISO9001"])
        end
      end

      context "the provider is published even under an unpublished catalogue" do
        before do
          create(:provider, catalogue_id: catalogue.id)
          catalogue.update_column(:status, "unpublished")
          put backoffice_provider_path(provider), params: update_params, as: :turbo_stream
        end

        it "does not crash" do
          expect(response).to have_http_status(:success)
        end
      end
    end
  end
end
