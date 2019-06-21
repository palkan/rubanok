# typed: true
# frozen_string_literal: true

using(Module.new do
  refine NilClass do
    def empty?
      true
    end
  end

  refine Object do
    def empty?
      false
    end
  end
end)

module Rubanok
  class Rule # :nodoc:
    extend T::Sig

    UNDEFINED = :__undef__

    attr_reader :fields, :activate_on, :activate_always

    sig do
      params(
        fields: T::Array[Symbol],
        activate_on: T.any(Symbol, T::Array[Symbol]),
        activate_always: T::Boolean
      )
        .void
    end
    def initialize(fields, activate_on: fields, activate_always: false)
      @fields = fields.freeze
      @activate_on = Array(activate_on).freeze
      @activate_always = activate_always
    end

    sig { params(params: T::Hash[Symbol, T.untyped]).returns(T::Hash[Symbol, T.untyped]) }
    def project(params)
      fields.each_with_object({}) do |field, acc|
        val = fetch_value params, field
        next acc if val == UNDEFINED

        acc[field] = val
        acc
      end
    end

    sig { params(params: T::Hash[Symbol, T.untyped]).returns(T::Boolean) }
    def applicable?(params)
      return true if activate_always == true

      activate_on.all? { |field| params.key?(field) && !empty?(params[field]) }
    end

    sig { returns(String) }
    def to_method_name
      @method_name ||= build_method_name
    end

    private

    sig { returns(String) }
    def build_method_name
      "__#{fields.join("_")}__"
    end

    sig { params(params: T::Hash[Symbol, T.untyped], field: Symbol).returns(T.untyped) }
    def fetch_value(params, field)
      return UNDEFINED if !params.key?(field) || empty?(params[field])

      params[field]
    end

    sig { params(val: T.untyped).returns(T::Boolean) }
    def empty?(val)
      return false unless Rubanok.ignore_empty_values

      val.empty?
    end
  end
end
