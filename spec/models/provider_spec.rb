# frozen_string_literal: true

require "rails_helper"
require_relative "publishable"

RSpec.describe Provider, type: :model, backend: true do
  include_examples "publishable"

  describe "validations" do
    it { should validate_presence_of(:name) }
    it { should validate_length_of(:legal_statuses) }
    it { should have_many(:services) }
    it { should have_many(:service_providers).dependent(:destroy) }
    it { should have_many(:categorizations) }
    it { should have_many(:categories) }
    it { should have_many(:provider_scientific_domains).dependent(:destroy) }
    it { should have_many(:provider_vocabularies).dependent(:destroy) }

    subject { create(:provider) }
  end

  describe "pid" do
    let(:provider) { build(:provider) }

    context "when pid is nil" do
      before { provider.pid = nil }

      it "assigns a generated pid" do
        expect { provider.valid? }.to change(provider, :pid).from(nil).to(be_present)
      end
    end

    context "when pid is blank" do
      before { provider.pid = "  " }

      it "assigns a generated pid" do
        expect { provider.valid? }.to change(provider, :pid).from("  ").to(be_present)
      end
    end

    context "when pid is nil and validations are skipped" do
      before do
        provider.pid = nil
        provider.save(validate: false)
      end

      it "persists a generated pid" do
        expect(provider.reload.pid).to be_present
      end
    end

    context "when pid is blank and validations are skipped" do
      before do
        provider.pid = "  "
        provider.save(validate: false)
      end

      it "persists a generated pid" do
        expect(provider.reload.pid).to be_present
      end
    end

    context "when pid is present" do
      let(:provider) { build(:provider, pid: "custom-pid") }

      it "keeps the given pid" do
        expect { provider.valid? }.not_to change(provider, :pid).from("custom-pid")
      end
    end

    context "when pid is already taken by another provider" do
      let(:provider) { build(:provider, pid: "taken-pid") }

      before { create(:provider, pid: "taken-pid") }

      it "is invalid" do
        expect(provider).not_to be_valid
      end

      it "reports the pid as taken" do
        provider.valid?
        expect(provider.errors[:pid]).to include("has already been taken")
      end

      it "is rejected by the database when validations are skipped" do
        expect { provider.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end
  end

  context "OMS validations" do
    subject { build(:provider, omses: build_list(:provider_group_oms, 2)) }
    it { should have_many(:omses) }
  end
end
