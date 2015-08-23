require "cucumber/rspec/doubles"
require 'capybara/poltergeist'

DatabaseCleaner.strategy = :truncation
Cucumber::Rails::Database.javascript_strategy = :truncation

# ActionController::Base.allow_rescue = false

Before do |scenario|
  DatabaseCleaner.clean
  eval File.read("#{Rails.root}/db/seeds.rb")

  system "rm -f #{Rails.root}/config/kor.app.test.yml"
  Kor.config true

  if scenario.source_tags.any?{|st| st.name == "@elastic"}
    Kor::Elastic.reset_index
  else
    allow(Kor::Elastic).to receive(:enabled?).and_return(false)
    allow(Kor::Elastic).to receive(:request).and_return([200, {}, {}])
  end
end

Capybara.register_driver :poltergeist do |app|
  Capybara::Poltergeist::Driver.new(app,
    # :debug => true,
    :js_errors => true,
    :inspector => true
  )
end

if ENV['HEADLESS']
  Capybara.javascript_driver = :poltergeist
end