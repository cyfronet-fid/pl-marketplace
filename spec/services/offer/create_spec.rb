# frozen_string_literal: true

require "rails_helper"

RSpec.describe Offer::Create, backend: true do
  subject(:create_offer) { described_class.call(offer) }

  let(:service) { create(:service, offers_count: 0) }

  context "when the offer is invalid" do
    let(:offer) { build(:offer, service: service, primary_oms_id: -1) }

    it "does not reindex or propagate the failed offer" do
      expect(service).not_to receive(:reindex)
      expect(offer).not_to receive(:reindex)

      expect { create_offer }.not_to have_enqueued_job(Ess::UpdateJob)

      expect(offer).not_to be_persisted
      expect(offer.errors[:primary_oms]).to include("doesn't exist")
    end
  end

  context "when the offer is valid" do
    let(:offer) { build(:offer, service: service) }

    before do
      allow(service).to receive(:reindex)
      allow(offer).to receive(:reindex)
    end

    it "propagates the service with its updated offers count" do
      expect { create_offer }.to have_enqueued_job(Ess::UpdateJob).with(
        hash_including("data_type" => "service", "data" => hash_including("id" => service.id, "offers_count" => 1))
      )

      expect(offer).to be_persisted
      expect(service.offers_count).to eq(1)
    end
  end
end
