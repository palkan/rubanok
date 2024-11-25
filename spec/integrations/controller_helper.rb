# frozen_string_literal: true

require "spec_helper"

require_relative "dummy/config/environment"
require "rspec/rails"

ActiveSupport.on_load(:action_controller) do
  require "rubanok/rails/controller"

  ActionController::Base.include Rubanok::Controller
end

ActiveSupport.on_load(:action_controller_api) do
  require "rubanok/rails/controller"

  ActionController::API.include Rubanok::Controller
end

SharedTestRoutes = ActionDispatch::Routing::RouteSet.new

SharedTestRoutes.draw do
  ActiveSupport::Deprecation.new.silence do
    get ":controller(/:action)"
  end
end
