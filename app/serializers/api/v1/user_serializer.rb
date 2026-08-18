# frozen_string_literal: true

class Api::V1::UserSerializer < ActiveModel::Serializer
  attributes :uid, :roles, :providers, :catalogues

  def roles
    object.roles.map(&:to_s)
  end

  def providers
    object.providers.pluck(:pid)
  end

  def catalogues
    object.catalogues.pluck(:pid)
  end
end
