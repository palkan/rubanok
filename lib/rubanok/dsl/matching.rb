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
      end

      def match(*fields)
      end
    end
  end
end
