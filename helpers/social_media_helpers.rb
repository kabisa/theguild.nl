# frozen_string_literal: true

module SocialMediaHelpers
  def page_title
    h(current_page.data.title || yield_content(:title) || data.config.site_title)
  end

  def page_description
    current_page.data.description || yield_content(:description) || data.config.site_subtitle
  end

  def current_page_url
    "#{config.site_url}#{current_page.url}"
  end

  def page_twitter_card_type
    current_page.data.twitter_card_type || 'summary_large_image'
  end

  def twitter_card_social_image
    # https://dev.twitter.com/cards/types/summary-large-image
    social_image(w: 560)
  end

  def news_article_schema_image
    social_image(w: 1200) || data.config.site_url + '/images/theguild-logo.png'
  end

  def facebook_social_image
    # https://developers.facebook.com/docs/sharing/best-practices
    social_image(w: 1200)
  end

  def social_image(opts = {})
    return unless url = yield_content(:social_image)

    contentful_image_url(prepend_protocol(url), opts)
  end

  private

  # See: https://www.contentful.com/developers/docs/references/images-api/
  # for available params
  def contentful_image_url(url, options = {})
    "#{url}?#{URI.encode_www_form(options)}"
  end

  def prepend_protocol(url, protocol = 'https')
    "#{protocol}:#{url}" if url
  end
end
