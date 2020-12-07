# frozen_string_literal: true

require "rubanok/version"
require "rubanok/processor"

require "rubanok/railtie" if defined?(Rails)

# @type const ENV: Hash[String, String]
if defined?(RSpec) && (ENV["RACK_ENV"] == "test" || ENV["RAILS_ENV"] == "test")
  require "rubanok/rspec"
end

# Rubanok provides a DSL to build parameters-based data transformers.
#
# Example:
#
#   class CourseSessionProcessor < Rubanok::Processor
#     map :q do |q:|
#       raw.searh(q)
#     end
#   end
#
#   class CourseSessionController < ApplicationController
#     def index
#       @sessions = rubanok_process(CourseSession.all)
#     end
#   end
module Rubanok
  class << self
    # Define whether to ignore empty values in params or not.
    # When the value is empty and ignored the corresponding matcher/mapper
    # is not activated (true by default)
    attr_accessor :ignore_empty_values
    # Define wheter to fail when `match` rule cannot find matching value
    attr_accessor :fail_when_no_matches
  end

  self.ignore_empty_values = true
  self.fail_when_no_matches = false
end
