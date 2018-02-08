require "middleman"
require 'rspec'
require 'capybara/rspec'
require 'capybara/poltergeist'

Capybara.javascript_driver = :poltergeist

Capybara.app = Middleman::Application.server.inst do
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
