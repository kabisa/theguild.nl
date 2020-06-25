# frozen_string_literal: true

# If you do not have OpenSSL installed, update
# the following line to use "http://" instead
source 'https://rubygems.org'

# For faster file watcher updates on Windows:
gem 'wdm', '~> 0.1.0', platforms: %i[mswin mingw]

# Windows does not come with time zone data
gem 'tzinfo-data', platforms: %i[mswin mingw jruby]

# Middleman Gems
gem 'middleman'
gem 'middleman-livereload'

gem 'contentful_middleman'
gem 'middleman-autoprefixer'
gem 'middleman-dotenv'
gem 'middleman-search_engine_sitemap'
gem 'middleman-syntax'
gem 'middleman-sprockets' # needed after MM 4.3 version
gem 'nokogiri'

gem 'builder' # XMLfeeds
gem 'html2slim' # Use `bundle exec erb2slim|html2slim -h` for more info
gem 'slim'

gem 'rack', '2.1.4' # https://github.com/middleman/middleman/issues/2309

# Testing
group :development do
  gem 'capybara'
  gem 'poltergeist'
  gem 'pry'
  gem 'rake'
  gem 'rspec'
end
