# frozen_string_literal: true

require "rails_helper"

RSpec.describe "common_parts/modals/_provider_approval_modal", type: :view do
  it "explains first-provider approval and links to service creation" do
    render partial: "common_parts/modals/provider_approval_modal"

    dialog = Capybara.string(rendered).find("#provider-approval-modal", visible: :all)

    expect(dialog["aria-labelledby"]).to eq("provider-approval-modal-title")
    expect(dialog["aria-describedby"]).to eq("provider-approval-modal-description")
    expect(dialog).to have_text("Congratulations! You've successfully created your first Provider.")
    expect(dialog).to have_text(
      "Your first Provider must be approved by our Technical Team before it can be published. " \
        "Until approval is granted, the Provider, its Services, and Offers will remain unpublished.",
      normalize_ws: true
    )
    expect(dialog).to have_css("strong", text: "Your first Provider must be approved by our Technical Team")
    expect(dialog).to have_css('button[aria-label="Close"]')
    expect(dialog["data-controller"]).to eq("dialog")
    expect(dialog).to have_css('button[data-action="dialog#close"]', count: 2)
    expect(dialog).to have_button("Cancel")
    expect(dialog).to have_link("Create your first service", href: new_backoffice_service_path)
  end
end
