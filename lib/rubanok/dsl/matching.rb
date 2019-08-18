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
      class Rule < Rubanok::Rule
        METHOD_PREFIX = "__match"

        class Clause < Rubanok::Rule
          attr_reader :values, :id, :block

          def initialize(id, fields, values = [], **options, &block)
            super(fields, options)
            @id = id
            @block = block
            @values = Hash[fields.take(values.size).zip(values)].freeze
            @fields = (fields - @values.keys).freeze
          end

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

        def matching_clause(params)
          clauses.detect do |clause|
            clause.applicable?(params)
          end
        end

        def having(*values, &block)
          clauses << Clause.new("#{to_method_name}_#{clauses.size}", fields, values, &block)
        end

        def default(&block)
          clauses << Clause.new("#{to_method_name}_default", fields, activate_always: true, &block)
        end

        private

        # prefix rule method name to avoid collisions
        def build_method_name
          "#{METHOD_PREFIX}#{super}"
        end
      end

      module InstanceMethods
        def default_match_handler(rule, params, fail_when_no_matches)
          fail_when_no_matches = Rubanok.fail_when_no_matches if fail_when_no_matches.nil?
          return raw unless fail_when_no_matches

          fail ::Rubanok::BadValueError, <<~MSG
            Bad value(s) for #{rule.fields.join(", ")}: #{params.slice(*rule.fields).values.join(", ")}
          MSG
        end
      end

      def self.extended(base)
        base.include InstanceMethods
      end

      def match(*fields, **options, &block)
        rule = Rule.new(fields, options.slice(:activate_on, :activate_always))

        rule.instance_eval(&block)

        define_method(rule.to_method_name) do |params = {}|
          @clause = rule.matching_clause(params)
          next default_match_handler(rule, params, options[:fail_when_no_matches]) unless @clause

          apply_rule! @clause.to_method_name, @clause.project(params)
        end

        rule.clauses.each do |clause|
          define_method(clause.to_method_name, &clause.block)
        end

        rules << rule
      end
    end
  end
end
