# frozen_string_literal: true

require "swagger_helper"
require "rails_helper"

RSpec.describe Api::V1::UsersController, swagger_doc: "v1/users_swagger.json", backend: true do
  before(:all) do
    Dir.chdir Rails.root.join("swagger", "v1") # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  after(:all) do
    Dir.chdir Rails.root # Workaround for rswag bug: https://github.com/rswag/rswag/issues/393
  end

  path "/api/v1/users/{user_id}" do
    get "Get user roles" do
      tags "Users"
      produces "application/json"
      security [authentication_token: []]
      parameter name: :user_id, in: :path, type: :string, description: "Unique identifier of the user"

      response 200, "successful" do
        schema "$ref" => "user/user_read.json"

        let(:admin) { create(:user, roles_mask: 7) }
        let!(:target_user) { create(:user, roles_mask: 5) }
        let!(:data_administrator) { create(:data_administrator, email: target_user.email) }
        let!(:provider) { create(:provider, data_administrators: [data_administrator]) }
        let!(:catalogue) { create(:catalogue, data_administrators: [data_administrator]) }

        let(:"X-User-Token") { admin.authentication_token }
        let(:user_id) { target_user.uid }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq(JSON.parse(Api::V1::UserSerializer.new(target_user.reload).to_json))
          expect(data["roles"]).to match_array(%w[admin executive])
          expect(data["providers"]).to eq([provider.pid])
          expect(data["catalogues"]).to eq([catalogue.pid])
        end
      end

      response 401, "user not recognized" do
        schema "$ref" => "error.json"
        let(:"X-User-Token") { "invalid-token" }
        let(:user_id) { "does-not-matter" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "You need to sign in or sign up before continuing." }.deep_stringify_keys)
        end
      end

      response 401, "user not authorized", document: false do
        schema "$ref" => "error.json"

        let(:requester) { create(:user, roles_mask: 1) }
        let!(:target_user) { create(:user) }
        let(:"X-User-Token") { requester.authentication_token }
        let(:user_id) { target_user.uid }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq({ error: "Not authorized" }.deep_stringify_keys)
        end
      end

      response 404, "user not found" do
        schema "$ref" => "error.json"

        let(:admin) { create(:user, roles_mask: 7) }
        let(:"X-User-Token") { admin.authentication_token }
        let(:user_id) { "does-not-exist" }

        run_test! do |response|
          data = JSON.parse(response.body)
          expect(data).to eq(
            { error: "User not found", message: "User with uid 'does-not-exist' does not exist" }.deep_stringify_keys
          )
        end
      end
    end
  end
end
