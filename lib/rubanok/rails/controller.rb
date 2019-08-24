# frozen_string_literal: true

require "active_support/concern"

module Rubanok
  # Controller concern.
  # Adds `rubanok_process` method.
  module Controller
    extend ActiveSupport::Concern

    included do
      helper_method :rubanok_scope
      helper_method :planish_scope
    end

    # This method process passed data (e.g. ActiveRecord relation) using
    # the corresponding Processor class.
    #
    # Processor is inferred from controller name, e.g.
    # "PostsController -> PostProcessor".
    #
    # You can specify the Processor class explicitly via `with` option.
    #
    # By default, `params` object is passed as parameters, but you
    # can specify the params via `params` option.
    def rubanok_process(data, params = nil, with: nil)
      with_inferred_rubanok_params(with, params) do |rubanok_class, rubanok_params|
        rubanok_class.call(data, rubanok_params)
      end
    end

    # This method filters the passed params and returns the Hash (!)
    # of the params recongnized by the processor.
    #
    # Processor is inferred from controller name, e.g.
    # "PostsController -> PostProcessor".
    #
    # You can specify the Processor class explicitly via `with` option.
    #
    # By default, `params` object is passed as parameters, but you
    # can specify the params via `params` option.
    def rubanok_scope(params = nil, with: nil)
      with_inferred_rubanok_params(with, params) do |rubanok_class, rubanok_params|
        rubanok_class.project(rubanok_params)
      end
    end

    # Tries to infer the rubanok processor class from controller path
    def implicit_rubanok_class
      "#{controller_path.classify.pluralize}Processor".safe_constantize
    end

    def with_inferred_rubanok_params(with, params)
      with ||= implicit_rubanok_class

      if with.nil?
        raise ArgumentError, "Failed to find a processor class for #{self.class.name}. " \
                             "Please, specify the processor class explicitly via `with` option"
      end

      params ||= self.params

      params = params.to_unsafe_h if params.is_a?(ActionController::Parameters)

      yield with, params
    end

    # Backward compatibility
    def planish(*args, with: implicit_plane_class)
      rubanok_process(*args, with: with)
    end

    def planish_scope(*args, with: implicit_plane_class)
      rubanok_scope(*args, with: with)
    end

    def implicit_plane_class
      "#{controller_path.classify.pluralize}Plane".safe_constantize
    end
  end
end
