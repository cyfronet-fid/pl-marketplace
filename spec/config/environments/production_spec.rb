# frozen_string_literal: true

require "rails_helper"
require "open3"

RSpec.describe "Production environment", backend: true do
  let(:base_environment) do
    {
      "RAILS_ENV" => "production",
      "SECRET_KEY_BASE_DUMMY" => "1",
      "ROOT_URL" => "https://marketplace.example.org",
      "SMTP_ADDRESS" => nil,
      "SMTP_PORT" => nil,
      "SMTP_USERNAME" => nil,
      "SMTP_PASSWORD" => nil,
      "SMTP_AUTHENTICATION" => nil,
      "SMTP_STARTTLS" => nil,
      "SMPT_ADDRESS" => nil,
      "SMPT_USERNAME" => nil,
      "SMPT_PASSWORD" => nil
    }
  end
  let(:configuration_script) { <<~RUBY }
      require "json"
      require_relative "config/application"
      require_relative "config/environments/production"

      settings = Rails.application.config.action_mailer.smtp_settings
      puts JSON.generate(settings.slice(:address, :port, :user_name, :password, :authentication,
                                        :enable_starttls_auto))
    RUBY

  def load_smtp_settings(environment)
    stdout, stderr, status =
      Open3.capture3(environment, RbConfig.ruby, "-e", configuration_script, chdir: Rails.root.to_s)

    expect(status).to be_success, stderr

    JSON.parse(stdout, symbolize_names: true)
  end

  it "loads SMTP settings from the documented environment variables" do
    environment =
      base_environment.merge(
        "SMTP_ADDRESS" => "smtp.example.org",
        "SMTP_PORT" => "2525",
        "SMTP_USERNAME" => "mailer",
        "SMTP_PASSWORD" => "secret",
        "SMTP_AUTHENTICATION" => "login",
        "SMTP_STARTTLS" => "false",
        "SMPT_ADDRESS" => "legacy-smtp.example.org",
        "SMPT_USERNAME" => "legacy-mailer",
        "SMPT_PASSWORD" => "legacy-secret"
      )

    expect(load_smtp_settings(environment)).to eq(
      address: "smtp.example.org",
      port: 2525,
      user_name: "mailer",
      password: "secret",
      authentication: "login",
      enable_starttls_auto: false
    )
  end

  it "supports the legacy misspelled credential variables" do
    environment =
      base_environment.merge(
        "SMPT_ADDRESS" => "legacy-smtp.example.org",
        "SMPT_USERNAME" => "legacy-mailer",
        "SMPT_PASSWORD" => "legacy-secret"
      )

    expect(load_smtp_settings(environment)).to eq(
      address: "legacy-smtp.example.org",
      port: 587,
      user_name: "legacy-mailer",
      password: "legacy-secret",
      authentication: "plain",
      enable_starttls_auto: true
    )
  end
end
