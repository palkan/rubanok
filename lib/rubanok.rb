# frozen_string_literal: true

require "rubanok/version"
require "rubanok/plane"

require "rubanok/railtie" if defined?(Rails)

if defined?(RSpec) && (ENV["RACK_ENV"] == "test" || ENV["RAILS_ENV"] == "test")
  require "rubanok/rspec"
end

# Rubanok provides a DSL to build parameters-based data transformers.
#
# Example:
#
#   class CourseSessionPlane < Rubanok::Plane
#     map :q do |q:|
#      raw.searh(q)
#     end
#   end
#
#   class CourseSessionController < ApplicationController
#     def index
#       @sessions = planish(CourseSession.all)
#     end
#   end
module Rubanok
  class << self
    # Define whether to ignore empty values in params or not.
    # When the value is empty and ignored the corresponding matcher/mapper
    # is not activated (true by default)
    attr_accessor :ignore_empty_values
  end

  self.ignore_empty_values = true
end
