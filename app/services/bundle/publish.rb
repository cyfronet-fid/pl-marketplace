# frozen_string_literal: true

class Bundle::Publish < Bundle::ApplicationService
  def call
    if @bundle.update(status: :published)
      notify_bundled!
      @bundle.service.reindex
      @bundle.offers.reindex
    else
      return false
    end
    @bundle
  end
end
