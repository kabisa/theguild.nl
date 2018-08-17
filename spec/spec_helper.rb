require 'rspec'
require 'capybara/rspec'
require 'capybara/poltergeist'

require 'middleman-core'
require 'middleman-core/rack'

require 'middleman-syntax'
require 'middleman-dotenv'
require 'middleman-livereload'
require 'middleman/search_engine_sitemap'
require 'contentful_middleman'
require 'middleman-autoprefixer'

Capybara.javascript_driver = :poltergeist

middleman_app = ::Middleman::Application.new
Capybara.app = ::Middleman::Rack.new(middleman_app).to_app do
  set :root, File.expand_path(File.join(File.dirname(__FILE__), '..'))
  set :environment, :development
  set :show_exceptions, false
end

RSpec.configure do |config|
  config.before(:each, js: true, type: :feature) do
    # typekit raises js error which crashes poltergeist
    page.driver.browser.url_blacklist = %w(http://use.typekit.net)
  end
end
