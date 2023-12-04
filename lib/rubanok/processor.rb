# frozen_string_literal: true

require "set"

require "rubanok/rule"

require "rubanok/dsl/mapping"
require "rubanok/dsl/matching"
require "rubanok/dsl/process"

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
    extend DSL::Matching::ClassMethods
    include DSL::Matching
    extend DSL::Mapping::ClassMethods
    include DSL::Mapping
    extend DSL::Process::ClassMethods
    include DSL::Process

    UNDEFINED = Object.new

    class << self
      def call(input, params = UNDEFINED)
        input, params = nil, input if params == UNDEFINED

        raise ArgumentError, "Params could not be nil" if params.nil?

        # @type var params: untyped
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
        params = params.transform_keys(&:to_sym)
        params.slice(*fields_set.to_a)
      end

      # DSL to define the #prepare method
      def prepare(&block)
        define_method(:prepare, &block)
      end
    end

    def initialize(input)
      @input = input
      @prepared = false
    end

    def call(params)
      params = params.transform_keys(&:to_sym)

      rules.each do |rule|
        next unless rule.applicable?(params)

        prepare! unless prepared?
        apply_rule! rule, params
      end

      input
    end

    private

    attr_accessor :input, :prepared

    alias_method :raw, :input
    alias_method :prepared?, :prepared

    def apply_rule!(rule, params)
      method_name, data = rule.to_method_name, rule.project(params)

      return unless data

      self.input =
        if data.empty?
          send(method_name)
        else
          send(method_name, **data)
        end
    end

    def prepare
      # no-op
    end

    def prepare!
      @prepared = true

      prepared_input = prepare
      return unless prepared_input

      self.input = prepared_input
    end

    def rules
      self.class.rules
    end
  end

  Plane = Processor
end
