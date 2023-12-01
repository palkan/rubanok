# frozen_string_literal: true

module Rubanok
  class UnexpectedInputError < StandardError; end

  module DSL
    # Adds `.match` method to Processor class to define key-value-matching rules:
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

          def initialize(id, fields, values, activate_on: fields, activate_always: false, &block)
            super(fields, activate_on: activate_on, activate_always: activate_always)
            @id = id
            @block = block
            @values = fields.take(values.size).zip(values).to_h.freeze
            @fields = (fields - @values.keys).freeze
          end

          def applicable?(params)
            values.all? { |key, matcher| params.key?(key) && (matcher == params[key]) }
          end

          alias_method :to_method_name, :id
        end

        attr_reader :clauses

        def initialize(fields, activate_on: fields, activate_always: false, ignore_empty_values: Rubanok.ignore_empty_values, filter_with: nil)
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
          clauses << Clause.new("#{to_method_name}_default", fields, [], activate_always: true, &block)
        end

        private

        # prefix rule method name to avoid collisions
        def build_method_name
          "#{METHOD_PREFIX}#{super}"
        end
      end

      module ClassMethods
        def match(*fields, activate_on: fields, activate_always: false, fail_when_no_matches: nil, &block)
          rule = Rule.new(fields, activate_on: activate_on, activate_always: activate_always)

          rule.instance_eval(&block)

          define_method(rule.to_method_name) do |params = {}|
            params ||= {}

            clause = rule.matching_clause(params)

            if clause
              apply_rule! clause, params
            else
              default_match_handler(rule, params, fail_when_no_matches)
            end
          end

          rule.clauses.each do |clause|
            define_method(clause.to_method_name, &clause.block)
          end

          add_rule rule
        end
      end

      def default_match_handler(rule, params, fail_when_no_matches)
        fail_when_no_matches = Rubanok.fail_when_no_matches if fail_when_no_matches.nil?
        return raw unless fail_when_no_matches

        raise ::Rubanok::UnexpectedInputError, <<~MSG
          Unexpected input: #{params.slice(*rule.fields)}.
          Available values are:
            #{rule.clauses.map(&:values).join("\n  ")}
        MSG
      end
    end
  end
end
