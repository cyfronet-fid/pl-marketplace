# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ess::Add, backend: true do
  let(:node) { Vocabulary::Node.create!(eid: "node-a", name: "Node A") }
  let!(:datasource) { create(:datasource, nodes: [node]) }
  let!(:service) { create(:service, nodes: [node]) }

  before { clear_enqueued_jobs }

  it "uses the Discovery Hub profile for service updates" do
    expect { described_class.call(service, "service", propagate_offers: false) }.to have_enqueued_job(
      Ess::UpdateJob
    ).with do |payload|
      expect(payload["data_type"]).to eq("service")
      expect(payload["data"]).to include("id" => service.id, "nodes" => [node.name])
      expect(payload["data"]).not_to have_key("node")
    end
  end

  it "uses the datasource profile for datasource updates" do
    expect { described_class.call(datasource, "data source", propagate_offers: false) }.to have_enqueued_job(
      Ess::UpdateJob
    ).with(
      hash_including("data_type" => "data source", "data" => hash_including("id" => datasource.id, "node" => node.name))
    )
  end
end
