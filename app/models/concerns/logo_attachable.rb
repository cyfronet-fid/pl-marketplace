# frozen_string_literal: true

module LogoAttachable
  include ImageHelper

  def logo_variable
    errors.add(:logo, ImageHelper::PERMITTED_EXT_MESSAGE) if logo.present? && !logo.variable?
  end

  def update_logo!(logo)
    blob, ext = ImageHelper.base_64_to_blob_stream(logo["base64"])
    path = ImageHelper.to_temp_file(blob, ext)
    self.logo.attach(io: File.open(path), filename: logo["filename"])
  end

  def set_default_logo(image_name = "eosc-img.png")
    image_path = Rails.root.join("app/assets/images", image_name)

    io = File.open(image_path, "rb")
    io = convert_to_png(io) unless File.extname(image_path) == ".png"

    logo.attach(io: io, filename: "#{SecureRandom.uuid}.png" , content_type: "image/png")
  end

  def convert_to_png(logo)
    img = Vips::Image.new_from_buffer(logo.read, "")
    logo.rewind

    scale = [800.0 / img.width, 800.0 / img.height].min
    img = img.resize(scale)

    StringIO.new(img.write_to_buffer(".png"))
  end
end
