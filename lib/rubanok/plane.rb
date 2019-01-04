# frozen_string_literal: true

require "rubanok/rule"

require "rubanok/dsl/mapping"
require "rubanok/dsl/matching"

require "rubanok/ext/symbolize_keys"
using Rubanok::SymbolizeKeys

module Rubanok
  # Base class for transformers (_planes_)
  #
  # Define transformation rules via `map` and `match` methods
  # and apply them by calling the plane:
  #
  #   class MyPlane < Rubanok::Plane
  #     map :type do
  #       raw.where(type: type)
  #     end
  #   end
  #
  #   MyPlane.call(MyModel.all, {type: "public"})
  #
  # NOTE: the second argument (`params`) MUST be a Hash. Keys could be either Symbols
  # or Strings (we automatically transform strings to symbols while matching rules).
  #
  # All transformation methods are called within the context of the instance of
  # a plane class.
  #
  # You can access the input data via `raw` method.
  class Plane
    class << self
      include DSL::Mapping
      include DSL::Matching

      def call(input, params)
        new(input).call(params)
      end

      def add_rule(rule)
        rules << rule
      end

      def rules
        return @rules if instance_variable_defined?(:@rules)

        @rules =
          if superclass <= Plane
            superclass.rules.dup
          else
            []
          end
      end
    end

    def initialize(input)
      @input = input
    end

    def call(params)
      params = params.symbolize_keys

      rules.each do |rule|
        next unless rule.applicable?(params)

        apply_rule! rule.to_method_name, rule.project(params)
      end

      input
    end

    private

    attr_accessor :input

    alias raw input

    def apply_rule!(method_name, data)
      self.input =
        if data.empty?
          send(method_name)
        else
          send(method_name, **data)
        end
    end

    def rules
      self.class.rules
    end
  end
end
