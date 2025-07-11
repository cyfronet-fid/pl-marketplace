# frozen_string_literal: true

require "rails_helper"

RSpec.describe Backoffice::ProviderPolicy, backend: true do
  subject { described_class }

  permissions :edit?, :destroy? do
    it "grants access for service portfolio manager" do
      expect(subject).to permit(build(:user, roles: [:coordinator]), build(:provider))
    end

    it "denies for deleted provider" do
      expect(subject).to_not permit(build(:user, roles: [:coordinator]), build(:provider, status: :deleted))
    end

    it "denies for other users" do
      expect(subject).to_not permit(create(:user), build(:provider))
    end
  end

  permissions :index?, :show?, :new?, :create? do
    it "grants access for service portfolio manager" do
      expect(subject).to permit(build(:user, roles: [:coordinator]))
    end

    it "denies for other users" do
      user = create(:user)
      expect(subject).to_not permit(user)
    end
  end
end
