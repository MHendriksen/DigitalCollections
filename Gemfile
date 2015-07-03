source 'https://rubygems.org'

gem 'rails', '3.2.21'
gem 'strong_parameters'

gem 'delayed_paperclip', "= 2.4.5", :require => 'delayed_paperclip/railtie'
gem "paperclip", "= 2.4.5"
gem "cocaine", "~> 0.2.1"
gem 'delayed_job_active_record'
gem 'delayed_job'
gem 'daemons'

gem 'mysql2'
gem "RedCloth"
gem "uuidtools"
gem "will_paginate", "= 3.0.3"
gem "parslet"
gem "exifr", '1.1.1'
gem "haml"
gem "sass"
gem 'httpclient'
gem 'mime-types', '1.16', :require => 'mime/types'
gem 'acts-as-taggable-on', '~> 2.2.2'
gem 'system_timer', :platforms => [:ruby_18]

gem 'kor_index', :path => './plugins/kor_index'

gem "sprockets"
gem "jquery-rails"
gem 'jquery-ui-rails'
gem 'angularjs-rails'
gem 'plupload-rails'
gem 'coffee-rails'
gem "sass-rails"

gem 'awesome_nested_set', :git => 'https://github.com/galetahub/awesome_nested_set.git'

gem 'oj'
gem 'jbuilder'

group :assets do
  gem "therubyracer"
  gem 'uglifier', '>= 1.0.3'
end

group :test do
  gem 'cucumber-rails', :require => false
  gem 'poltergeist'
  gem 'selenium-webdriver'
  gem 'rspec-rails', '~> 3.1'
  gem 'capybara'
  gem 'database_cleaner'
  gem 'factory_girl_rails'
end

group :development do
  # gem 'method_profiler'
end

group :test, :development do
  gem 'thin'
  gem 'quiet_assets'
  gem 'pry'
end

group :production do
  gem 'puma'
end

group :import_export do
  gem 'mixlib-cli'
  gem 'spreadsheet'
end