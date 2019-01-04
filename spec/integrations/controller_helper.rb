# frozen_string_literal: true

require "spec_helper"

require "action_controller"
require "action_view"
require "rspec/rails"

SharedTestRoutes = ActionDispatch::Routing::RouteSet.new

SharedTestRoutes.draw do
  ActiveSupport::Deprecation.silence do
    get ":controller(/:action)"
  end
end
