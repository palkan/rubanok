# typed: true
# frozen_string_literal: true

module Rubanok
  module DSL
    # Adds `.match` method to Plane class to define key-value-matching rules:
    #
    #   match :sort, :sort_by do |sort:, sort_by:|
    #     # this rule is activated iff both "sort" and "sort_by" params are present
    #     # the values are passed to the matcher
    #     #
    #     # then we match against values
    #     having "name" do |sort_by:|
    #       raw.joins(:user).order("users.name #{sort_by}")
    #     end
    #   end
    module Matching
      extend T::Sig
      extend T::Helpers

      abstract!

      class Rule < Rubanok::Rule
        METHOD_PREFIX = "__match"

        class Clause < Rubanok::Rule
          extend T::Sig

          attr_reader :values, :id, :block

          sig do
            params(
              id: String,
              fields: T::Array[Symbol],
              values: T::Array[T.untyped],
              activate_on: T.any(Symbol, T::Array[Symbol]),
              activate_always: T::Boolean,
              block: T.proc.void
            )
              .void
          end
          def initialize(id, fields, values = [], activate_on: fields, activate_always: false, &block)
            super(fields, activate_on: activate_on, activate_always: activate_always)
            @id = id
            @block = block
            @values = Hash[fields.take(values.size).zip(values)].freeze
            @fields = (fields - @values.keys).freeze
          end

          sig { params(params: T::Hash[T.any(Symbol, String), T.untyped]).returns(T::Boolean) }
          def applicable?(params)
            values.all? { |key, matcher| params.key?(key) && (matcher == params[key]) }
          end

          alias to_method_name id
        end

        attr_reader :clauses

        def initialize(*)
          super
          @clauses = []
        end

        sig { params(params: T::Hash[T.any(Symbol, String), T.untyped]).returns(T.nilable(Clause)) }
        def matching_clause(params)
          clauses.detect do |clause|
            clause.applicable?(params)
          end
        end

        sig { params(values: T.untyped, block: T.proc.void).returns(T::Array[Clause]) }
        def having(*values, &block)
          clauses << Clause.new("#{to_method_name}_#{clauses.size}", fields, values, &block)
        end

        sig { params(block: T.proc.void).returns(T::Array[Clause]) }
        def default(&block)
          clauses << Clause.new("#{to_method_name}_default", fields, activate_always: true, &block)
        end

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
      def match(*fields, activate_on: fields, activate_always: false, &block)
        rule = Rule.new(fields, activate_on: activate_on, activate_always: activate_always)

        rule.instance_eval(&block)

        define_method(rule.to_method_name) do |params = {}|
          clause = rule.matching_clause(params)
          next raw unless clause

          apply_rule! clause.to_method_name, clause.project(params)
        end

        rule.clauses.each do |clause|
          define_method(clause.to_method_name, &clause.block)
        end

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
