###
# Compass
###

# Change Compass configuration
# compass_config do |config|
#   config.output_style = :compact
# end

###
# Page options, layouts, aliases and proxies
###

# Per-page layout changes:
#
# With no layout
# page "/path/to/file.html", :layout => false
#
# With alternative layout
# page "/path/to/file.html", :layout => :otherlayout
#
# A path which all have the same layout
# with_layout :admin do
#   page "/admin/*"
# end

# Proxy pages (https://middlemanapp.com/advanced/dynamic_pages/)
# proxy "/this-page-has-no-template.html", "/template-file.html", :locals => {
#  :which_fake_page => "Rendering a fake page with a local variable" }

###
# Helpers
###

# Automatic image dimensions on image_tag helper
# activate :automatic_image_sizes

# Reload the browser automatically whenever files change
configure :development do
  activate :livereload
end

# Methods defined in the helpers block are available in templates
# helpers do
#   def some_helper
#     "Helping"
#   end
# end

set :css_dir, 'stylesheets'

set :js_dir, 'javascripts'

set :images_dir, 'images'

# Build-specific configuration
configure :build do
  # For example, change the Compass output style for deployment
  activate :minify_css

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
#
# Activate before using any ENV defined in `.env`
activate :dotenv

activate :contentful do |f|
  f.space              = { site: '8v4g74v8oew0' }
  f.access_token       = ENV['TECH_BLOG_ACCESS_TOKEN']
  f.use_preview_api    = true if ENV['TECH_BLOG_ENVIRONMENT'] == 'preview'
  #f.cda_query          = QUERY
  #
  # To get the id for the content type, in Contentful go to
  # `APIs`, `Content Types`
  f.content_types      = {
    author:          '22AHer1UygAKmCC4KOMQ4M',
    category:        '3hGz8Hs0VG8mYaauKssyk4',
    post:            '2bSTvV1Q7ug20QoKmM0cIA'
  }
end

activate :autoprefixer do |config|
  config.browsers = ['last 2 versions', 'Explorer >= 9']
end

if data['site']
  @posts = data.site.post.values.sort_by(&:createdOn).reverse

  @posts.each do |post|
    proxy "#{post.slug}.html", 'templates/post.html', locals: { post: post }, ignore: true
  end
end

# Move partials out of the way of regular pages
set :partials_dir, 'partials/'

# Force HTML5 to avoid self-closing tags
Slim::Engine.options[:format] = :html
# Set slim-lang output style
Slim::Engine.options[:pretty] = true
