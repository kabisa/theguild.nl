#
# Compass


# Change Compass configuration
# compass_config do |config|
  # config.output_style = :compact
# end


# Page options, layouts, aliases and proxies


# Per-page layout changes:

# With no layout
# page "/path/to/file.html", :layout => false

# With alternative layout
# page "/path/to/file.html", :layout => :otherlayout

# A path which all have the same layout
# with_layout :admin do
  # page "/admin/*"
# end

# Proxy pages (https://middlemanapp.com/advanced/dynamic_pages/)
# proxy "/this-page-has-no-template.html", "/template-file.html", :locals => {
 # :which_fake_page => "Rendering a fake page with a local variable" }


# Helpers


# Automatic image dimensions on image_tag helper
# activate :automatic_image_sizes

# Reload the browser automatically whenever files change
configure :development do
  activate :livereload
end

# Sitemap configuration
set :url_root, @app.data.config.site_url
activate :search_engine_sitemap

activate :contentful do |f|
  f.space              = { site: '8v4g74v8oew0' }
  f.access_token       = ENV['THE_GUILD_WEBSITE_ACCESS_TOKEN']
  f.use_preview_api    = true if ENV['THE_GUILD_WEBSITE_ENVIRONMENT'] == 'preview'
  f.cda_query          = { limit: 1000 }

  # To get the id for the content type, in Contentful go to
  # `APIs`, `Content Types`
  f.content_types      = {
    author:          '22AHer1UygAKmCC4KOMQ4M',
    category:        '3hGz8Hs0VG8mYaauKssyk4',
    post:            '2bSTvV1Q7ug20QoKmM0cIA',
    page:            '59E4QY5S3eGyAsga0Csmsg',
    snippet:         'snippet'
  }
end

activate :autoprefixer do |config|
  config.browsers = ['last 2 versions', 'Explorer >= 9']
end

# Methods defined in the helpers block are available in templates
# helpers do
  # def some_helper
    # "Helping"
  # end
# end

set :css_dir, 'stylesheets'

set :js_dir, 'javascripts'

set :images_dir, 'images'

# Build-specific configuration
configure :build do
  # For example, change the Compass output style for deployment
  activate :minify_css, inline: true

  # Minify Javascript on build
  activate :minify_javascript

  # Enable cache buster
  activate :asset_hash

  # Use relative URLs
  # activate :relative_assets

  # Or use a different image path
  # set :http_prefix, "/Content/images/"
end

activate :directory_indexes

# https://github.com/middleman/middleman-syntax
# Syntax highlighting via Rouge
activate :syntax, line_numbers: true

# https://github.com/middleman-contrib/middleman-dotenv
# Dotenv for Middleman
# Loads environment variables from `.env`

# Activate before using any ENV defined in `.env`
activate :dotenv

after_configuration do
  if @app.data && @app.data[:site]
    posts = @app.data.site.post.values.sort_by(&:created_on).reverse

    posts.each do |post|
      proxy "#{post.slug}.html",
        'templates/post.html', locals: { post: post }, ignore: true
    end
  end
end

# Create RSS Feed xml
page @app.data.config.feed_path, layout: false

# Force HTML5 to avoid self-closing tags
Slim::Engine.options[:format] = :html
# Set slim-lang output style
Slim::Engine.options[:pretty] = true

# Middleman places all pages in a folder with its name and
# index.html inside it. Netlify is looking for pages like 404.html
# at the root of site folder
after_build do
  # Netlify

  FileUtils.cp 'build/404/index.html', 'build/404.html'

  # End Netlify
end
