# frozen_string_literal: true

require "rails_helper"

RSpec.describe Ess::ServiceSerializer, backend: true do
  subject(:data) { described_class.new(service).as_json }

  let(:node) { Vocabulary::Node.create!(eid: "node-a", name: "Node A") }
  let(:public_contact) { build(:public_contact, email: "contact@example.org") }
  let(:multimedia_url) { build(:link_multimedia_url, url: "https://example.org/video") }
  let(:use_case_url) { build(:link_use_cases_url, url: "https://example.org/use-case") }
  let(:service) do
    create(
      :service,
      nodes: [node],
      public_contacts: [public_contact],
      link_multimedia_urls: [multimedia_url],
      link_use_cases_urls: [use_case_url]
    )
  end

  it "serializes the service using the Discovery Hub profile" do
    expect(data).to include(
      nodes: [node.name],
      public_contact_emails: [public_contact.email],
      trls: service.trls.first.name,
      urls: [multimedia_url.url, use_case_url.url]
    )
    expect(data).not_to include(:node, :public_contacts, :trl, :multimedia_urls, :use_cases_urls)
  end

  context "when the service has a logo" do
    before do
      service.logo.attach(
        io: Rails.root.join("spec/fixtures/files/PhenoMeNal_logo.png").open,
        filename: "service-logo.png",
        content_type: "image/png"
      )
    end

    it "serializes its public logo route" do
      logo_path = Rails.application.routes.url_helpers.service_logo_path(service)

      expect(data[:logo]).to end_with(logo_path)
    end
  end
end
