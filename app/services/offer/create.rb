# frozen_string_literal: true

class Offer::Create < Offer::ApplicationService
  def call
    return @offer unless @offer.save

    @service.reload
    @service.propagate_to_ess(propagate_offers: false)
    @service.reindex
    @offer.reindex
    @offer
  end
end
