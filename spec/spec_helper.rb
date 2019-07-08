# typed: false
# frozen_string_literal: true

ENV["RACK_ENV"] = "test"

require "bundler/setup"

begin
  require "pry-byebug"
rescue LoadError
end

if ENV["CC_REPORT"]
  require "simplecov"
  SimpleCov.start do
    add_filter "/spec/"
  end
end

require "rubanok"

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"

  config.filter_run focus: true
  config.run_all_when_everything_filtered = true

  config.order = :random

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
