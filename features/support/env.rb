# IMPORTANT: This file is generated by cucumber-rails - edit at your own peril.
# It is recommended to regenerate this file in the future when you upgrade to a
# newer version of cucumber-rails. Consider adding your own code to a new file
# instead of editing this one. Cucumber will automatically load all features/**/*.rb
# files.

system "cat /dev/null >| log/test.log"

require 'cucumber/rails'
require 'cucumber/rspec/doubles'
require 'capybara/poltergeist'

Capybara.default_selector = :css

Capybara.register_driver :selenium do |app|
  Capybara::Selenium::Driver.new(app, :browser => :chrome)
end

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app, 
    :js_errors => false,
    :inspector => true
  )
end

if ENV['HEADLESS']
  Capybara.javascript_driver = :poltergeist
end

ActionController::Base.allow_rescue = false

Before do |scenario|

  file = "#{Rails.root}/tmp/harmful.txt"
  system "rm #{file}" if File.exists?(file)

  if scenario.source_tags.any?{|st| st.name == "@elastic"}
    Kor::Elastic.reset_index
  else
    allow(Kor::Elastic).to receive(:request).and_return([200, {}, {}])
  end
end

ActiveSupport::Deprecation.behavior = Proc.new do |message, stack|
  message << ":\n"
  stack.each do |l|
    message << "#{l}\n" if l.match(Rails.root)
  end
  
  deprecation_logger.info "#{message}#{'-' * 80}"
end

# Capybara defaults to CSS3 selectors rather than XPath.
# If you'd prefer to use XPath, just uncomment this line and adjust any
# selectors in your step definitions to use the XPath syntax.
# Capybara.default_selector = :xpath

# By default, any exception happening in your Rails application will bubble up
# to Cucumber so that your scenario will fail. This is a different from how 
# your application behaves in the production environment, where an error page will 
# be rendered instead.
#
# Sometimes we want to override this default behaviour and allow Rails to rescue
# exceptions and display an error page (just like when the app is running in production).
# Typical scenarios where you want to do this is when you test your error pages.
# There are two ways to allow Rails to rescue exceptions:
#
# 1) Tag your scenario (or feature) with @allow-rescue
#
# 2) Set the value below to true. Beware that doing this globally is not
# recommended as it will mask a lot of errors for you!
#
ActionController::Base.allow_rescue = false

# Remove/comment out the lines below if your app doesn't have a database.
# For some databases (like MongoDB and CouchDB) you may need to use :truncation instead.
begin
  DatabaseCleaner.strategy = :truncation
rescue NameError
  raise "You need to add database_cleaner to your Gemfile (in the :test group) if you wish to use it."
end

# You may also want to configure DatabaseCleaner to use different strategies for certain features and scenarios.
# See the DatabaseCleaner documentation for details. Example:
#
#   Before('@no-txn,@selenium,@culerity,@celerity,@javascript') do
#     # { :except => [:widgets] } may not do what you expect here
#     # as Cucumber::Rails::Database.javascript_strategy overrides
#     # this setting.
#     DatabaseCleaner.strategy = :truncation
#   end
#
#   Before('~@no-txn', '~@selenium', '~@culerity', '~@celerity', '~@javascript') do
#     DatabaseCleaner.strategy = :transaction
#   end
#

# Possible values are :truncation and :transaction
# The :transaction strategy is faster, but might give you threading problems.
# See https://github.com/cucumber/cucumber-rails/blob/master/features/choose_javascript_database_strategy.feature
Cucumber::Rails::Database.javascript_strategy = :truncation


# deprecation_log_file = "#{Rails.root}/log/test.deprecation.log"
# system "rm #{deprecation_log_file}" if File.exists?(deprecation_log_file)
# deprecation_logger = Logger.new(deprecation_log_file)