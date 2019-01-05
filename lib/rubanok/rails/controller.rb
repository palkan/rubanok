# frozen_string_literal: true

require "active_support/concern"

module Rubanok
  # Controller concern.
  # Adds `planish` method.
  module Controller
    extend ActiveSupport::Concern

    # Planish passed data (e.g. ActiveRecord relation) using
    # the corrsponding Plane class.
    #
    # Plane is inferred from controller name, e.g.
    # "PostsController -> PostPlane".
    #
    # You can specify the Plane class explicitly via `with` option.
    #
    # By default, `params` object is passed as paraters, but you
    # can specify the params via `params` option.
    def planish(data, plane_params = nil, with: implicit_plane_class)
      if with.nil?
        raise ArgumentError, "Failed to find a plane class for #{self.class.name}. " \
                             "Please, specify the plane class explicitly via `with` option"
      end

      plane_params ||= params

      plane_params = plane_params.to_unsafe_h if plane_params.is_a?(ActionController::Parameters)
      with.call(data, plane_params)
    end

    # Tries to infer the plane class from controller path
    def implicit_plane_class
      "#{controller_path.classify.pluralize}Plane".safe_constantize
    end
  end
end
