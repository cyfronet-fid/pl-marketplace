# frozen_string_literal: true

require "rails_helper"

RSpec.describe LogoAttachable, type: :model, backend: true do
  describe "#set_default_logo" do
    context "with no argument" do
      subject(:catalogue) { build(:catalogue) }

      before do
        allow(catalogue).to receive(:convert_to_png).and_call_original
      end

      it "attaches the default eosc-img.png logo" do
        catalogue.set_default_logo
        expect(catalogue.logo).to be_attached
      end

      it "attaches it as a PNG" do
        catalogue.set_default_logo
        expect(catalogue.logo.content_type).to eq("image/png")
      end

      it "attaches it with UUID filename" do
        catalogue.set_default_logo
        expect(catalogue.logo.filename.to_s).to match(/\A[0-9a-f-]{36}\.png\z/)
      end

      it "does not run the image through PNG conversion, since it is already a PNG" do
        catalogue.set_default_logo
        expect(catalogue).not_to have_received(:convert_to_png)
      end
    end

    context "when given an asset name that already has a .png extension" do
      subject(:catalogue) { build(:catalogue) }

      before do
        allow(catalogue).to receive(:convert_to_png).and_call_original
      end

      it "does not convert it" do
        catalogue.set_default_logo("eosc-img.png")
        expect(catalogue).not_to have_received(:convert_to_png)
      end
    end

    context "when given a non-png asset name (e.g. an SVG)" do
      subject(:provider) { build(:provider) }

      before do
        allow(provider).to receive(:convert_to_png).and_call_original
      end

      it "attaches the the logo" do
        provider.set_default_logo("provider_logo.svg")
        expect(provider.logo).to be_attached
      end

      it "converts image to PNG" do
        provider.set_default_logo("provider_logo.svg")
        expect(provider).to have_received(:convert_to_png)
      end

      it "sets PNG content type" do
        provider.set_default_logo("provider_logo.svg")
        expect(provider.logo.content_type).to eq("image/png")
      end

      it "sets filename with PNG extension" do
        provider.set_default_logo("provider_logo.svg")
        expect(provider.logo.filename.to_s).to end_with(".png")
      end
    end

    context "when the requested asset does not exist" do
      subject(:catalogue) { build(:catalogue) }

      it "raises an error" do
        expect { catalogue.set_default_logo("does-not-exist.png") }.to raise_error(Errno::ENOENT)
      end
    end
  end
end
