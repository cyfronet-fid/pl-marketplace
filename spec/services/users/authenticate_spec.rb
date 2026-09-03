# frozen_string_literal: true

require "rails_helper"

RSpec.describe Users::Authenticate, backend: true do
  subject(:result) { described_class.call(auth) }

  let(:auth) do
    {
      "provider" => provider,
      "uid" => uid,
      "info" => {
        "email" => email,
        "email_verified" => email_verified,
        "first_name" => "John",
        "last_name" => "Doe"
      }
    }
  end
  
  let(:provider) { "checkin" }
  let(:uid) { "uid-123" }
  let(:email) { "john.doe@email.pl" }
  let(:email_verified) { true }

  context "when an identity already exists for the provider and uid" do
    let(:existing_user) { create(:user) }

    before { create(:user_identity, user: existing_user, provider: provider, uid: uid, primary: false) }

    it "returns the identity's user" do
      expect(result).to eq(existing_user)
    end

    it "does not create a new user" do
      expect { result }.not_to change(User, :count)
    end
  end

  context "when no identity matches but a user exists with the same email" do
    let!(:existing_user) { create(:user, email: email) }

    it "returns the existing user" do
      expect(result).to eq(existing_user)
    end

    it "adds a non-primary identity for the provider and uid" do
      result
      expect(existing_user.identities.reload.find_by(provider: provider, uid: uid)).to have_attributes(primary: false)
    end
  end

  context "when a user exists with the same email but the provider did not verify it" do
    let(:email_verified) { false }

    let!(:existing_user) { create(:user, email: email) }

    it "does not return the existing user" do
      expect(result).not_to eq(existing_user)
    end

    it "does not link a new identity to the existing user" do
      expect { result }.not_to change { existing_user.identities.reload.count }
    end

    it "does not persist a new user, since the email is already taken" do
      expect(result).not_to be_persisted
    end
  end

  context "when neither an identity nor an email match exists" do
    it "creates a new user" do
      expect { result }.to change(User, :count).by(1)
    end

    it "creates a primary identity for the new user" do
      expect(result.identities.find_by(provider: provider, uid: uid)).to have_attributes(primary: true)
    end
  end
end
