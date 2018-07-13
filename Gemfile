# If you do not have OpenSSL installed, update
# the following line to use "http://" instead
source 'https://rubygems.org'

ruby '2.3.0'

# For faster file watcher updates on Windows:
gem "wdm", "~> 0.1.0", :platforms => [:mswin, :mingw]

# Windows does not come with time zone data
gem "tzinfo-data", platforms: [:mswin, :mingw, :jruby]

# Middleman Gems
gem 'middleman'
gem "middleman-livereload"

gem 'contentful_middleman'
gem 'middleman-dotenv'
gem 'middleman-syntax'
gem 'middleman-autoprefixer'
gem 'middleman-search_engine_sitemap'
gem 'nokogiri', '~> 1.8.1'

gem 'slim'
gem 'html2slim' # Use `bundle exec erb2slim|html2slim -h` for more info
gem 'builder' # XMLfeeds

# Testing
group :development do
  gem 'rake'
  gem 'rspec'
  gem 'capybara'
  gem 'poltergeist'
  gem 'pry'
end
