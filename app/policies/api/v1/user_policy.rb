# frozen_string_literal: true

class Api::V1::UserPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      user&.roles_mask == 7 ? scope.all : scope.none
    end
  end

  def show?
    user&.roles_mask == 7
  end
end
