# frozen_string_literal: true

class Ess::Add < ApplicationService
  def initialize(object, type, async: true, propagate_offers: true)
    super()
    @object = object
    @type = type
    @async = async
    @propagate_offers = propagate_offers
  end

  def call
    if @propagate_offers && @object.is_a?(Service) && @object.offers.published&.size&.positive?
      @object.offers.each(&:save)
    end

    @async ? Ess::UpdateJob.perform_later(payload) : Ess::Update.call(payload)
  end

  private

  def payload
    serializer_type = @object.is_a?(Service) ? "Service" : @object.class.name
    {
      action: "update",
      data_type: @type,
      data: "Ess::#{serializer_type}Serializer".constantize.new(@object).as_json
    }.as_json
  end
end
