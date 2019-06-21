# typed: false
# frozen_string_literal: true

require "rspec/mocks"

module Rubanok
  class HavePlanished < RSpec::Matchers::BuiltIn::BaseMatcher
    include RSpec::Mocks::ExampleMethods

    attr_reader :data_class, :plane, :matcher

    def initialize(data_class = nil)
      if data_class
        @data_class = data_class.is_a?(Module) ? data_class : data_class.class
      end
      @matcher = have_received(:call)
    end

    def with(plane)
      @plane = plane
      self
    end

    def supports_block_expectations?
      true
    end

    def matches?(proc)
      raise ArgumentError, "have_planished only supports block expectations" unless Proc === proc

      raise ArgumentError, "Plane class is required. Please, specify it using `.with` modifier" if plane.nil?

      allow(plane).to receive(:call).and_call_original
      proc.call

      matcher.with(an_instance_of(data_class), anything) if data_class

      matcher.matches?(plane)
    end

    def failure_message
      "expected to use #{plane.name}#{data_class ? " for #{data_class.name}" : ""}, but didn't"
    end

    def failure_message_when_negated
      "expected not to use #{plane.name}#{data_class ? " for #{data_class.name} " : ""}, but have used"
    end
  end
end

RSpec.configure do |config|
  config.include(Module.new do
    def have_planished(*args)
      Rubanok::HavePlanished.new(*args)
    end
  end)
end
