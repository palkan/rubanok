# frozen_string_literal: true

require "rspec/mocks"

module Rubanok
  class HaveProcessed < RSpec::Matchers::BuiltIn::BaseMatcher
    include RSpec::Mocks::ExampleMethods

    attr_reader :data_class, :processor, :matcher

    def initialize(data_class = nil)
      if data_class
        @data_class = data_class.is_a?(Module) ? data_class : data_class.class
      end
      @matcher = have_received(:call)
      @name = "have_rubanok_processed"
    end

    def as(alias_name)
      @name = alias_name
      self
    end

    def with(processor)
      @processor = processor
      self
    end

    def supports_block_expectations?
      true
    end

    def matches?(proc)
      raise ArgumentError, "#{name} only supports block expectations" unless Proc === proc

      raise ArgumentError, "Processor class is required. Please, specify it using `.with` modifier" if processor.nil?

      allow(processor).to receive(:call).and_call_original
      proc.call

      matcher.with(an_instance_of(data_class), anything) if data_class

      matcher.matches?(processor)
    end

    def failure_message
      "expected to use #{processor.name}#{data_class ? " for #{data_class.name}" : ""}, but didn't"
    end

    def failure_message_when_negated
      "expected not to use #{processor.name}#{data_class ? " for #{data_class.name} " : ""}, but have used"
    end

    private

    attr_reader :name
  end
end

RSpec.configure do |config|
  config.include(Module.new do
    def have_rubanok_processed(*args)
      Rubanok::HaveProcessed.new(*args)
    end

    def have_planished(*args)
      Rubanok::HaveProcessed.new(*args).as("have_planished")
    end
  end)
end
