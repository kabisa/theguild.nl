# frozen_string_literal: true

module FaviconHelper
  def favicon_image_path(asset_path)
    data.config.site_url + image_path(asset_path)
  end
end
