# frozen_string_literal: true

require "rails_helper"

RSpec.describe Backoffice::ProviderPolicy, backend: true do
  subject { described_class }

  let(:coordinator) { create(:user, roles: [:coordinator]) }
  let(:admin) { create(:user, roles: [:admin]) }
  let(:owner) { create(:user) }
  let(:catalogue_owner) { create(:user) }
  let(:stranger) { create(:user) }
  let(:catalogue) do
    create(:catalogue, data_administrators: [build(:data_administrator, email: catalogue_owner.email)])
  end
  let(:provider_status) { :published }
  let(:provider) do
    create(:provider, status: provider_status, data_administrators: [build(:data_administrator, email: owner.email)])
  end
  let(:catalogue_provider) { create(:provider, catalogue_id: catalogue.id) }

  permissions :index?, :new?, :create?, :exit? do
    it "grants access for coordinator" do
      expect(subject).to permit(coordinator, Provider)
    end

    it "grants access for admin" do
      expect(subject).to permit(admin, Provider)
    end

    it "grants access for any signed in user" do
      expect(subject).to permit(stranger, Provider)
    end

    it "denies for anonymous user" do
      expect(subject).to_not permit(nil, Provider)
    end
  end

  permissions :show?, :edit?, :update? do
    it "grants access for coordinator" do
      expect(subject).to permit(coordinator, provider)
    end

    it "grants access for admin" do
      expect(subject).to permit(admin, provider)
    end

    it "grants access for provider data administrator" do
      expect(subject).to permit(owner, provider)
    end

    it "grants access for catalogue data administrator" do
      expect(subject).to permit(catalogue_owner, catalogue_provider)
    end

    it "denies for user who does not manage the provider" do
      expect(subject).to_not permit(stranger, provider)
    end

    it "denies for anonymous user" do
      expect(subject).to_not permit(nil, provider)
    end

    context "when provider is deleted" do
      let(:provider_status) { :deleted }

      it "denies for coordinator" do
        expect(subject).to_not permit(coordinator, provider)
      end

      it "denies for admin" do
        expect(subject).to_not permit(admin, provider)
      end

      it "denies for provider data administrator" do
        expect(subject).to_not permit(owner, provider)
      end
    end
  end

  permissions :destroy? do
    it "grants access for coordinator" do
      expect(subject).to permit(coordinator, provider)
    end

    it "grants access for admin" do
      expect(subject).to permit(admin, provider)
    end

    it "grants access for provider data administrator" do
      expect(subject).to permit(owner, provider)
    end

    it "grants access for catalogue data administrator" do
      expect(subject).to permit(catalogue_owner, catalogue_provider)
    end

    it "denies for user who does not manage the provider" do
      expect(subject).to_not permit(stranger, provider)
    end

    it "denies for anonymous user" do
      expect(subject).to_not permit(nil, provider)
    end

    context "when approval request is pending" do
      before { create(:approval_request, approvable: provider) }

      it "grants access for coordinator" do
        expect(subject).to permit(coordinator, provider.reload)
      end

      it "grants access for admin" do
        expect(subject).to permit(admin, provider.reload)
      end

      it "denies for provider data administrator" do
        expect(subject).to_not permit(owner, provider.reload)
      end
    end

    context "when approval request is closed" do
      before { create(:approval_request, :accepted, approvable: provider) }

      it "grants access for provider data administrator" do
        expect(subject).to permit(owner, provider.reload)
      end
    end

    context "when provider is deleted" do
      let(:provider_status) { :deleted }

      it "denies for coordinator" do
        expect(subject).to_not permit(coordinator, provider)
      end

      it "denies for admin" do
        expect(subject).to_not permit(admin, provider)
      end
    end
  end

  permissions :publish? do
    context "when provider is unpublished" do
      let(:provider_status) { :unpublished }

      it "grants access for coordinator" do
        expect(subject).to permit(coordinator, provider)
      end

      it "grants access for admin" do
        expect(subject).to permit(admin, provider)
      end

      it "denies for user who does not manage the provider" do
        expect(subject).to_not permit(stranger, provider)
      end
    end

    context "when provider is already published" do
      let(:provider_status) { :published }

      it "denies for coordinator" do
        expect(subject).to_not permit(coordinator, provider)
      end

      it "denies for admin" do
        expect(subject).to_not permit(admin, provider)
      end
    end
  end

  permissions :unpublish? do
    context "when provider is published" do
      let(:provider_status) { :published }

      it "grants access for coordinator" do
        expect(subject).to permit(coordinator, provider)
      end

      it "grants access for admin" do
        expect(subject).to permit(admin, provider)
      end

      it "denies for user who does not manage the provider" do
        expect(subject).to_not permit(stranger, provider)
      end
    end

    context "when provider is already unpublished" do
      let(:provider_status) { :unpublished }

      it "denies for coordinator" do
        expect(subject).to_not permit(coordinator, provider)
      end

      it "denies for admin" do
        expect(subject).to_not permit(admin, provider)
      end
    end
  end

  permissions :suspend? do
    context "when provider is published" do
      let(:provider_status) { :published }

      it "grants access for coordinator" do
        expect(subject).to permit(coordinator, provider)
      end

      it "grants access for admin" do
        expect(subject).to permit(admin, provider)
      end

      it "denies for user who does not manage the provider" do
        expect(subject).to_not permit(stranger, provider)
      end
    end

    context "when provider is already suspended" do
      let(:provider_status) { :suspended }

      it "denies for coordinator" do
        expect(subject).to_not permit(coordinator, provider)
      end

      it "denies for admin" do
        expect(subject).to_not permit(admin, provider)
      end
    end
  end

  describe "Scope" do
    subject(:resolved) { described_class::Scope.new(user, Provider).resolve }

    let(:other_provider) { create(:provider) }

    before { [provider, catalogue_provider, other_provider] }

    context "for coordinator" do
      let(:user) { coordinator }

      it "returns all providers" do
        expect(resolved).to contain_exactly(provider, catalogue_provider, other_provider)
      end
    end

    context "for admin" do
      let(:user) { admin }

      it "returns all providers" do
        expect(resolved).to contain_exactly(provider, catalogue_provider, other_provider)
      end
    end

    context "for provider data administrator" do
      let(:user) { owner }

      it "returns providers managed directly by the user" do
        expect(resolved).to contain_exactly(provider)
      end
    end

    context "for catalogue data administrator" do
      let(:user) { catalogue_owner }

      it "returns providers managed through the user's catalogue" do
        pending "Provider.catalogue_managed_by filters on catalogues without joining them"

        expect(resolved).to contain_exactly(catalogue_provider)
      end
    end

    context "for user who manages no providers" do
      let(:user) { stranger }

      it "returns nothing" do
        expect(resolved).to be_empty
      end
    end

    context "for anonymous user" do
      let(:user) { nil }

      it "returns nothing" do
        expect(resolved).to be_empty
      end
    end
  end
end
