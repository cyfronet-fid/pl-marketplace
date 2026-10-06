# frozen_string_literal: true

require "rails_helper"

RSpec.describe Backoffice::ProviderPolicy, backend: true do
  subject { described_class }

  let(:coordinator) { create(:user, roles: [:coordinator]) }
  let(:owner) { create(:user) }
  let(:catalogue_owner) { create(:user) }
  let(:stranger) { create(:user) }
  let(:catalogue) do
    create(:catalogue, data_administrators: [build(:data_administrator, email: catalogue_owner.email)])
  end

  def provider_owned_by(user, **attrs)
    create(:provider, data_administrators: [build(:data_administrator, email: user.email)], **attrs)
  end

  permissions :index?, :new?, :create?, :exit? do
    it "grants access for coordinator" do
      expect(subject).to permit(coordinator, Provider)
    end

    it "grants access for any signed in user" do
      expect(subject).to permit(stranger, Provider)
    end

    it "denies for anonymous user" do
      expect(subject).to_not permit(nil, Provider)
    end
  end

  permissions :show?, :edit?, :update? do
    let(:provider) { provider_owned_by(owner) }

    it "grants access for coordinator" do
      expect(subject).to permit(coordinator, provider)
    end

    it "grants access for provider data administrator" do
      expect(subject).to permit(owner, provider)
    end

    it "grants access for catalogue data administrator" do
      provider = create(:provider, catalogue_id: catalogue.id)

      expect(subject).to permit(catalogue_owner, provider)
    end

    it "denies for user who does not manage the provider" do
      expect(subject).to_not permit(stranger, provider)
    end

    it "denies for anonymous user" do
      expect(subject).to_not permit(nil, provider)
    end

    it "denies coordinator for deleted provider" do
      expect(subject).to_not permit(coordinator, provider_owned_by(owner, status: :deleted))
    end

    it "denies provider data administrator for deleted provider" do
      expect(subject).to_not permit(owner, provider_owned_by(owner, status: :deleted))
    end
  end

  permissions :destroy? do
    let(:provider) { provider_owned_by(owner) }

    it "grants access for coordinator" do
      expect(subject).to permit(coordinator, provider)
    end

    it "grants access for provider data administrator" do
      expect(subject).to permit(owner, provider)
    end

    it "grants access for catalogue data administrator" do
      provider = create(:provider, catalogue_id: catalogue.id)

      expect(subject).to permit(catalogue_owner, provider)
    end

    it "grants access for coordinator while approval request is pending" do
      create(:approval_request, approvable: provider)

      expect(subject).to permit(coordinator, provider.reload)
    end

    it "denies provider data administrator while approval request is pending" do
      create(:approval_request, approvable: provider)

      expect(subject).to_not permit(owner, provider.reload)
    end

    it "grants access for provider data administrator once approval request is closed" do
      create(:approval_request, :accepted, approvable: provider)

      expect(subject).to permit(owner, provider.reload)
    end

    it "denies for user who does not manage the provider" do
      expect(subject).to_not permit(stranger, provider)
    end

    it "denies for anonymous user" do
      expect(subject).to_not permit(nil, provider)
    end

    it "denies for deleted provider" do
      expect(subject).to_not permit(coordinator, provider_owned_by(owner, status: :deleted))
    end
  end

  permissions :publish? do
    it "grants access for unpublished provider" do
      expect(subject).to permit(coordinator, provider_owned_by(owner, status: :unpublished))
    end

    it "denies for already published provider" do
      expect(subject).to_not permit(coordinator, provider_owned_by(owner, status: :published))
    end

    it "denies for user who does not manage the provider" do
      expect(subject).to_not permit(stranger, provider_owned_by(owner, status: :unpublished))
    end
  end

  permissions :unpublish? do
    it "grants access for published provider" do
      expect(subject).to permit(coordinator, provider_owned_by(owner, status: :published))
    end

    it "denies for already unpublished provider" do
      expect(subject).to_not permit(coordinator, provider_owned_by(owner, status: :unpublished))
    end

    it "denies for user who does not manage the provider" do
      expect(subject).to_not permit(stranger, provider_owned_by(owner, status: :published))
    end
  end

  permissions :suspend? do
    it "grants access for published provider" do
      expect(subject).to permit(coordinator, provider_owned_by(owner, status: :published))
    end

    it "denies for already suspended provider" do
      expect(subject).to_not permit(coordinator, provider_owned_by(owner, status: :suspended))
    end

    it "denies for user who does not manage the provider" do
      expect(subject).to_not permit(stranger, provider_owned_by(owner, status: :published))
    end
  end

  describe "Scope" do
    let!(:owned_provider) { provider_owned_by(owner) }
    let!(:catalogue_provider) { create(:provider, catalogue_id: catalogue.id) }
    let!(:other_provider) { create(:provider) }

    def resolve(user)
      described_class::Scope.new(user, Provider).resolve
    end

    it "returns all providers for coordinator" do
      expect(resolve(coordinator)).to contain_exactly(owned_provider, catalogue_provider, other_provider)
    end

    it "returns providers managed directly by the user" do
      expect(resolve(owner)).to contain_exactly(owned_provider)
    end

    it "returns providers managed through the user's catalogue" do
      pending "Provider.catalogue_managed_by filters on catalogues without joining them"

      expect(resolve(catalogue_owner)).to contain_exactly(catalogue_provider)
    end

    it "returns nothing for user who manages no providers" do
      expect(resolve(stranger)).to be_empty
    end

    it "returns nothing for anonymous user" do
      expect(resolve(nil)).to be_empty
    end
  end
end
