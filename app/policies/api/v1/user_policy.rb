# frozen_string_literal: true

class Api::V1::UserPolicy < ApplicationPolicy
  def show?
    # Requester must hold every role (admin+coordinator+executive), not just #admin? —
    # this endpoint is restricted to that full set per product requirements.
    user&.roles_mask == User.mask_for(:admin, :coordinator, :executive)
  end
end
