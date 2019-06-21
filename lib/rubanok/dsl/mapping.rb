# typed: true
# frozen_string_literal: true

module Rubanok
  module DSL
    # Adds `.map` method to Plane to define key-matching rules:
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

      def map(*fields, **options, &block)
        rule = Rule.new(fields, options)

        define_method(rule.to_method_name, &block)

        rules << rule
      end
    end
  end
end
