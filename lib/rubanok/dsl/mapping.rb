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
      extend T::Sig
      extend T::Helpers

      abstract!

      class Rule < Rubanok::Rule
        METHOD_PREFIX = "__map"

        private

        # prefix rule method name to avoid collisions
        def build_method_name
          "#{METHOD_PREFIX}#{super}"
        end
      end

      sig do
        params(
          fields: Symbol,
          activate_on: T.any(Symbol, T::Array[Symbol]),
          activate_always: T::Boolean,
          block: T.proc.void
        )
          .returns(T::Array[Rubanok::Rule])
      end
      def map(*fields, activate_on: fields, activate_always: false, &block)
        rule = Rule.new(fields, activate_on: activate_on, activate_always: activate_always)

        define_method(rule.to_method_name, &block)

        rules << rule
      end

      sig { abstract.returns(T::Array[Rubanok::Rule]) }
      def rules
      end

      sig do
        abstract
          .params(
            arg0: T.any(Symbol, String),
            blk: BasicObject,
          )
          .returns(Symbol)
      end
      def define_method(arg0, &blk)
      end
    end
  end
end
