# frozen_string_literal: true

require "rails_helper"

RSpec.describe Catalogue, type: :model, backend: true do
  describe "pid" do
    let(:catalogue) { build(:catalogue) }

    context "when pid is nil" do
      before { catalogue.pid = nil }

      it "assigns a generated pid" do
        expect { catalogue.valid? }.to change(catalogue, :pid).from(nil).to(be_present)
      end
    end

    context "when pid is blank" do
      before { catalogue.pid = "  " }

      it "assigns a generated pid" do
        expect { catalogue.valid? }.to change(catalogue, :pid).from("  ").to(be_present)
      end
    end

    context "when pid is nil and validations are skipped" do
      before do
        catalogue.pid = nil
        catalogue.save(validate: false)
      end

      it "persists a generated pid" do
        expect(catalogue.reload.pid).to be_present
      end
    end

    context "when pid is blank and validations are skipped" do
      before do
        catalogue.pid = "  "
        catalogue.save(validate: false)
      end

      it "persists a generated pid" do
        expect(catalogue.reload.pid).to be_present
      end
    end

    context "when pid is present" do
      let(:catalogue) { build(:catalogue, pid: "custom-pid") }

      it "keeps the given pid" do
        expect { catalogue.valid? }.not_to change(catalogue, :pid).from("custom-pid")
      end
    end

    context "when pid is already taken by another catalogue" do
      let(:catalogue) { build(:catalogue, pid: "taken-pid") }

      before { create(:catalogue, pid: "taken-pid") }

      it "is invalid" do
        expect(catalogue).not_to be_valid
      end

      it "reports the pid as taken" do
        catalogue.valid?
        expect(catalogue.errors[:pid]).to include("has already been taken")
      end

      it "is rejected by the database when validations are skipped" do
        expect { catalogue.save(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
      end
    end
  end
end
