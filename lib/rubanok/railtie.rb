# typed: strict
# frozen_string_literal: true

module Rubanok # :nodoc:
  class Railtie < ::Rails::Railtie # :nodoc:
    config.to_prepare do |_app|
      ActiveSupport.on_load(:action_controller) do
        require "rubanok/rails/controller"

        ActionController::Base.include Rubanok::Controller
      end

      ActiveSupport.on_load(:action_controller_api) do
        require "rubanok/rails/controller"

        ActionController::API.include Rubanok::Controller
      end
    end
  end
end
