xml.instruct!
xml.feed xmlns: "http://www.w3.org/2005/Atom" do
  site_url = "http://#{data.config.host}"

  xml.title "#{data.config.site_title}"
  xml.subtitle "#{data.config.site_subtitle}"
  xml.id URI(site_url)
  xml.link href: URI(site_url)
  xml.link href: URI.join(site_url, "/feed.xml"), rel: "self"
  xml.updated @posts.first.createdOn.to_time.iso8601
  xml.author do
    xml.name "#{data.config.author}"
    xml.email "#{data.config.email}"
  end

  @posts.first(10).each do |post|
    xml.entry do
      xml.title post.title
      xml.link rel: "alternate", href: URI.join(site_url, post.slug)
      xml.id URI.join(site_url, post.slug)
      xml.published post.createdOn.to_time.iso8601
      # xml.updated post.date.to_time.iso8601
      post.authors.each do |author|
        xml.author { xml.name author.name }
      end
      xml.summary post.summary, type: "html"
      xml.content Kramdown::Document.new(post.body).to_html, type: "html"
    end
  end
end
