# frozen_string_literal: true

require "rails_helper"

RSpec.describe Importable, backend: true do
  subject(:importer) { Class.new { include Importable }.new }

  let(:domain) { create(:scientific_domain, eid: "scientific_domain-natural_sciences") }
  let(:subdomain) do
    create(:scientific_domain, parent: domain, eid: "scientific_subdomain-natural_sciences-biological_sciences")
  end
  let(:category) { create(:category, eid: "category-data") }
  let(:subcategory) { create(:category, parent: category, eid: "subcategory-data-analysis") }

  describe "#map_scientific_domains" do
    subject(:mapped) { importer.map_scientific_domains(domains) }

    let(:domains) { [{ "scientificDomain" => domain.eid, "scientificSubdomain" => subdomain.eid }] }

    it "links the subdomain of a registry pair" do
      expect(mapped).to contain_exactly(subdomain)
    end

    context "when the pair has no subdomain" do
      let(:domains) { [{ "scientificDomain" => domain.eid, "scientificSubdomain" => "" }] }

      it "links the domain" do
        expect(mapped).to contain_exactly(domain)
      end
    end

    context "when given plain eids" do
      let(:domains) { [subdomain.eid] }

      it "links them" do
        expect(mapped).to contain_exactly(subdomain)
      end
    end

    context "when empty" do
      let(:domains) { nil }

      it { is_expected.to eq([]) }
    end
  end

  describe "#map_categories" do
    subject(:mapped) { importer.map_categories(categories) }

    let(:categories) { [{ "category" => category.eid, "subcategory" => subcategory.eid }] }

    it "links the subcategory of a registry pair" do
      expect(mapped).to contain_exactly(subcategory)
    end

    context "when the pair has no subcategory" do
      let(:categories) { [{ "category" => category.eid }] }

      it "links the category" do
        expect(mapped).to contain_exactly(category)
      end
    end
  end
end
