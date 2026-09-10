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

  context "OMS validations" do
    subject { build(:provider, omses: build_list(:provider_group_oms, 2)) }
    it { should have_many(:omses) }
  end

  describe "pid default value" do
    it "generates a random UUID v4 if pid is blank" do
      provider = build(:provider, pid: nil)
      provider.valid?
      expect(provider.pid).to be_present
      expect(provider.pid).to match(/\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/i)
    end

    it "keeps existing pid if present" do
      provider = build(:provider, pid: "custom-pid")
      provider.valid?
      expect(provider.pid).to eq("custom-pid")
    end
  end
end
