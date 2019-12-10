# frozen_string_literal: true

xml.instruct!
xml.feed xmlns: 'http://www.w3.org/2005/Atom' do
  site_url = data.config.site_url
  feed_path = data.config.feed_path

  xml.title data.config.site_title.to_s
  xml.subtitle data.config.site_subtitle.to_s
  xml.id URI(site_url)
  xml.link href: URI(site_url)
  xml.link href: URI.join(site_url, feed_path), rel: 'self'
  xml.updated posts.first.created_on.to_date.iso8601
  xml.author do
    xml.name data.config.author.to_s
    xml.email data.config.email.to_s
  end

  posts.first(10).each do |post|
    xml.entry do
      xml.title post.title
      xml.link rel: 'alternate', href: URI.join(site_url, post.slug)
      xml.id URI.join(site_url, post.slug)
      xml.published post.created_on.to_time.iso8601
      xml.updated DateTime.parse(post._meta.updated_at).to_time.iso8601
      post.authors.each do |author|
        xml.author { xml.name author.name }
      end
      xml.summary post.summary, type: 'html'
      xml.content render_markdown(post.body), type: 'html'
    end
  end
end
