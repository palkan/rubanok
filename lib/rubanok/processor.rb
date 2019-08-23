# frozen_string_literal: true

require "set"

require "rubanok/rule"

require "rubanok/dsl/mapping"
require "rubanok/dsl/matching"

require "rubanok/ext/symbolize_keys"
using Rubanok::SymbolizeKeys

module Rubanok
  # Base class for processors (_planes_)
  #
  # Define transformation rules via `map` and `match` methods
  # and apply them by calling the processor:
  #
  #   class MyTransformer < Rubanok::Processor
  #     map :type do
  #       raw.where(type: type)
  #     end
  #   end
  #
  #   MyTransformer.call(MyModel.all, {type: "public"})
  #
  # NOTE: the second argument (`params`) MUST be a Hash. Keys could be either Symbols
  # or Strings (we automatically transform strings to symbols while matching rules).
  #
  # All transformation methods are called within the context of the instance of
  # a processor class.
  #
  # You can access the input data via `raw` method.
  class Processor
    include DSL::Matching
    include DSL::Mapping

    class << self
      def call(input, params)
        new(input).call(params)
      end

      def add_rule(rule)
        fields_set.merge rule.fields
        rules << rule
      end

      def rules
        return @rules if instance_variable_defined?(:@rules)

        @rules =
          if superclass <= Processor
            superclass.rules.dup
          else
            []
          end
      end

      def fields_set
        return @fields_set if instance_variable_defined?(:@fields_set)

        @fields_set =
          if superclass <= Processor
            superclass.fields_set.dup
          else
            Set.new
          end
      end

      # Generates a `params` projection including only the keys used
      # by the rules
      def project(params)
        params.slice(*fields_set)
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

  Plane = Processor
end
