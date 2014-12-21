# Insert a tracking image at the bottom of the html email
class Filters::AddOpenTracking < Filters::Tracking
  include ActionView::Helpers::AssetTagHelper
  include Rails.application.routes.url_helpers

  attr_accessor :delivery_id, :enabled

  def initialize(delivery)
    options = {
      delivery: delivery,
      delivery_id: delivery.id,
      enabled: delivery.open_tracking_enabled?,
      tracking_domain: delivery.tracking_domain,
      using_custom_tracking_domain: delivery.custom_tracking_domain?
    }
    @delivery = options[:delivery]
    @delivery_id = options[:delivery_id]
    @enabled = options[:enabled]
    super(options)
  end

  def filter_html(input)
    if enabled
      delivery.set_open_tracked!
      # TODO Add image tag in a place to keep html valid (not just the end of the document)
      input + image_tag(url, alt: nil)
    else
      input
    end
  end

  # The url for the tracking image
  def url
    tracking_open_url(
      host: host,
      protocol: protocol,
      delivery_id: delivery_id,
      hash: HashId.hash(delivery_id),
      format: :gif
    )
  end
end
