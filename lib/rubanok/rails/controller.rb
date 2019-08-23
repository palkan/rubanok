# frozen_string_literal: true

require "active_support/concern"

module Rubanok
  # Controller concern.
  # Adds `rubanok_process` method.
  module Controller
    extend ActiveSupport::Concern

    # This method passed data (e.g. ActiveRecord relation) using
    # the corresponding Processor class.
    #
    # Processor is inferred from controller name, e.g.
    # "PostsController -> PostProcessor".
    #
    # You can specify the Processor class explicitly via `with` option.
    #
    # By default, `params` object is passed as parameters, but you
    # can specify the params via `params` option.
    def rubanok_process(data, plane_params = nil, with: implicit_rubanok_class)
      if with.nil?
        raise ArgumentError, "Failed to find a processor class for #{self.class.name}. " \
                             "Please, specify the processor class explicitly via `with` option"
      end

      plane_params ||= params

      plane_params = plane_params.to_unsafe_h if plane_params.is_a?(ActionController::Parameters)
      with.call(data, plane_params)
    end

    def planish(*args, with: implicit_plane_class)
      rubanok_process(*args, with: with)
    end

    # Tries to infer the rubanok processor class from controller path
    def implicit_rubanok_class
      "#{controller_path.classify.pluralize}Processor".safe_constantize
    end

    def implicit_plane_class
      "#{controller_path.classify.pluralize}Plane".safe_constantize
    end
  end
end
