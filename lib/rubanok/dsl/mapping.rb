# frozen_string_literal: true

module Rubanok
  module DSL
    # Adds `.map` method to Processor to define key-matching rules:
    #
    #   map :q do |q:|
    #    # this rule is activated iff "q" (or :q) param is present
    #    # the value is passed to the handler
    #   end
    module Mapping
      class Rule < Rubanok::Rule
        METHOD_PREFIX = "__map"

        private

        # prefix rule method name to avoid collisions
        def build_method_name
          "#{METHOD_PREFIX}#{super}"
        end
      end

      module ClassMethods
        def map(*fields, activate_on: fields, activate_always: false, ignore_empty_values: Rubanok.ignore_empty_values, filter_with: nil, &block)
          filter = filter_with

          if filter.is_a?(Symbol)
            respond_to?(filter) || raise(
              ArgumentError,
              "Unknown class method #{filter} for #{self}. " \
              "Make sure that a filter method is defined before the call to .map."
            )
            filter_with = method(filter)
          end

          rule = Rule.new(fields, activate_on: activate_on, activate_always: activate_always, ignore_empty_values: ignore_empty_values, filter_with: filter_with)

          define_method(rule.to_method_name, &block)

          add_rule rule
        end
      end

      def self.included(base)
        base.extend ClassMethods
      end
    end
  end
end
