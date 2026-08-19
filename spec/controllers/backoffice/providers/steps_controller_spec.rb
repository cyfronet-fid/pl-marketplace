# frozen_string_literal: true

require "rails_helper"

RSpec.describe Backoffice::Providers::StepsController, type: :controller, backend: true do
  describe "PUT #update" do
    let(:user) { create(:user, roles: [:coordinator]) }
    let(:main_contact_attributes) do
      { "first_name" => "Main", "last_name" => "Contact", "email" => "main.contact@example.com" }
    end
    let(:public_contact_attributes) do
      { "0" => { "first_name" => "Public", "last_name" => "Contact", "email" => "public.contact@example.com" } }
    end
    let(:data_administrator_attributes) do
      { "0" => { "first_name" => "Data", "last_name" => "Administrator", "email" => "data.administrator@example.com" } }
    end
    let(:provider_attributes) do
      {
        "name" => "Issue 106 provider",
        "main_contact_attributes" => main_contact_attributes,
        "public_contacts_attributes" => public_contact_attributes,
        "data_administrators_attributes" => data_administrator_attributes
      }
    end

    before do
      sign_in user
      session[:wizard_action] = "create"
      session[:provider_step] = "summary"
      session[:new] = provider_attributes
    end

    it "persists each nested contact and administrator once" do
      put :update, params: { provider_id: "new", commit: "Create provider" }

      provider = Provider.find_by!(name: provider_attributes["name"])

      expect(provider.main_contact.email).to eq(main_contact_attributes["email"])
      expect(provider.public_contacts.pluck(:email)).to eq([public_contact_attributes.dig("0", "email")])
      expect(provider.data_administrators.pluck(:email)).to eq([data_administrator_attributes.dig("0", "email")])
    end

    it "applies newly added nested records once when updating a provider" do
      provider = create(:provider)
      session.delete(:new)
      session[:wizard_action] = "update"
      session[provider.to_param] = {
        "public_contacts_attributes" => public_contact_attributes,
        "data_administrators_attributes" => data_administrator_attributes
      }

      put :update, params: { provider_id: provider.to_param, commit: "Update provider" }

      expect(provider.reload.public_contacts.where(email: public_contact_attributes.dig("0", "email")).count).to eq(1)
      expect(provider.data_administrators.where(email: data_administrator_attributes.dig("0", "email")).count).to eq(1)
    end

    context "when creating a provider that requires approval" do
      let(:user) { create(:user) }
      let(:data_administrator_attributes) do
        { "0" => { "first_name" => user.first_name, "last_name" => user.last_name, "email" => user.email } }
      end

      subject(:finish_wizard) { put :update, params: { provider_id: "new", commit: "Create provider" } }

      it "opens the approval guidance after the first provider" do
        expect { finish_wizard }.to change(ApprovalRequest, :count).by(1)

        provider = Provider.find_by!(name: provider_attributes["name"])
        approval_request = provider.approval_requests.find_by!(user: user)

        expect(approval_request).to have_attributes(approvable: provider, user: user, status: "published")
        expect(Backoffice::ServicePolicy.new(user.reload, Service.new).new?).to be(true)
        expect(response).to redirect_to(backoffice_providers_path)
        expect(session[:provider_approval_modal]).to be(true)
      end

      it "does not reopen the first-provider guidance for another provider" do
        create(:provider, status: :unpublished, data_administrators: [build(:data_administrator, email: user.email)])

        expect { finish_wizard }.to change(ApprovalRequest, :count).by(1)

        provider = Provider.find_by!(name: provider_attributes["name"])

        expect(response).to redirect_to(backoffice_providers_path)
        expect(session[:provider_approval_modal]).to be_nil
        expect(session[:provider_profile_completion]).to eq(provider.id)
      end
    end

    context "when a coordinator creates their first provider" do
      let(:data_administrator_attributes) do
        { "0" => { "first_name" => user.first_name, "last_name" => user.last_name, "email" => user.email } }
      end

      subject(:finish_wizard) { put :update, params: { provider_id: "new", commit: "Create provider" } }

      it "does not show approval guidance" do
        expect { finish_wizard }.not_to change(ApprovalRequest, :count)

        provider = Provider.find_by!(name: provider_attributes["name"])

        expect(response).to redirect_to(backoffice_providers_path)
        expect(session[:provider_approval_modal]).to be_nil
        expect(session[:provider_profile_completion]).to eq(provider.id)
      end
    end
  end
end
