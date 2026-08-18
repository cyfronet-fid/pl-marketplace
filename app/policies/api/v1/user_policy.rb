# frozen_string_literal: true

class Api::V1::UserPolicy < ApplicationPolicy
  # Requester must hold every role (admin+coordinator+executive), not just #admin? —
  # this endpoint is restricted to that full set per product requirements.
  ADMIN_ROLES_MASK = 7

  def show?
    user&.roles_mask == ADMIN_ROLES_MASK
  end
end
