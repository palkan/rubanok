# frozen_string_literal: true

module Rubanok
  module DSL
    # Adds `.process` method to Processor to define a nested processor:
    #
    #   process :filter do
    #     map :status do |status:|
    #       raw.where(status:)
    #     end
    #
    module Process
      class Rule < Rubanok::Rule
        METHOD_PREFIX = "__process"

        def initialize(...)
          super
          raise ArgumentError, "Nested processor requires exactly one field" if fields.size != 1
          @field = fields.first
        end

        def define_processor(superclass, &block)
          @processor = Class.new(superclass, &block)
        end

        def process(input, params)
          return input if params.nil?

          subparams = fetch_value(params, field)
          return input if subparams == UNDEFINED

          return input unless subparams.respond_to?(:transform_keys)

          # @type var subparams : params
          processor.call(input, subparams)
        end

        private

        attr_reader :processor, :field

        def build_method_name
          "#{METHOD_PREFIX}#{super}"
        end
      end

      module ClassMethods
        def process(field, superclass: ::Rubanok::Processor, activate_on: [field], activate_always: false, ignore_empty_values: Rubanok.ignore_empty_values, filter_with: nil, &block)
          filter = filter_with

          if filter.is_a?(Symbol)
            respond_to?(filter) || raise(
              ArgumentError,
              "Unknown class method #{filter} for #{self}. " \
              "Make sure that a filter method is defined before the call to .map."
            )
            filter = method(filter)
          end

          rule = Rule.new([field], activate_on: activate_on, activate_always: activate_always, ignore_empty_values: ignore_empty_values, filter_with: filter)
          rule.define_processor(superclass, &block)

          define_method(rule.to_method_name) do |params = {}|
            rule.process(raw, params)
          end

          add_rule rule
        end
      end
    end
  end
end
