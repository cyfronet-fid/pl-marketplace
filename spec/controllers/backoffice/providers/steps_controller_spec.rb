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
  end
end
