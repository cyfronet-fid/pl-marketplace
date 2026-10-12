# frozen_string_literal: true

require "rails_helper"

RSpec.describe Datasource, type: :model, backend: true do
  # The factory builds a Service with type "Datasource"; reload to get the Datasource class
  let(:datasource) { described_class.find(create(:datasource, abbreviation: abbreviation).id) }
  let(:abbreviation) { "ds-abbr" }

  it "shares the Service model name" do
    expect(described_class.model_name).to eq(Service.model_name)
  end

  it "reports its type" do
    expect(described_class.type).to eq("Datasource")
  end

  describe "pid" do
    context "when pid is nil and the datasource has a source" do
      before do
        datasource.sources.build(source_type: :eosc_registry, eid: "datasource-eid")
        datasource.pid = nil
      end

      it "uses the source eid" do
        expect { datasource.valid? }.to change(datasource, :pid).from(nil).to("datasource-eid")
      end
    end

    context "when pid is nil and the datasource has no source" do
      before { datasource.pid = nil }

      it "uses the abbreviation" do
        expect { datasource.valid? }.to change(datasource, :pid).from(nil).to("ds-abbr")
      end
    end

    context "when pid is nil and there is neither a source nor an abbreviation" do
      let(:abbreviation) { "" }

      before { datasource.pid = nil }

      it "assigns a generated pid" do
        expect { datasource.valid? }.to change(datasource, :pid).from(nil).to(be_present)
      end
    end

    context "when pid is blank" do
      before { datasource.pid = "  " }

      it "replaces it" do
        expect { datasource.valid? }.to change(datasource, :pid).from("  ").to("ds-abbr")
      end
    end

    context "when pid is nil and validations are skipped" do
      before do
        datasource.pid = nil
        datasource.save(validate: false)
      end

      it "persists the fallback pid" do
        expect(datasource.reload.pid).to eq("ds-abbr")
      end
    end

    context "when pid is present" do
      before do
        datasource.sources.build(source_type: :eosc_registry, eid: "datasource-eid")
        datasource.pid = "custom-pid"
      end

      it "keeps the given pid" do
        expect { datasource.valid? }.not_to change(datasource, :pid).from("custom-pid")
      end
    end
  end

  describe "persistent identity systems" do
    let(:entity_type) { Vocabulary::EntityType.create!(name: "Dataset", eid: "ds_research_entity_type-dataset") }

    before do
      datasource.persistent_identity_systems.build
      datasource.persistent_identity_systems.build(entity_type: entity_type)
      datasource.save!
    end

    it "drops systems without an entity type or schemes on save" do
      expect(datasource.reload.persistent_identity_systems.map(&:entity_type)).to eq([entity_type])
    end
  end
end
