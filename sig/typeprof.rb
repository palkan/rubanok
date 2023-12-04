# frozen_string_literal: true

# Run typeprofiler:
#
#   typeprof -Ilib sig/typeprof.rb
require "rubanok"

processor = Class.new(Rubanok::Processor) do
  map :q do |q:|
    raw
  end

  process :filter do
    map :status do |status:|
      raw
    end

    map :name do |name:|
      raw
    end
  end

  match :sort_by, :sort, activate_on: :sort_by do
    having "status", "asc" do
      raw
    end

    default do |sort_by:, sort: "asc"|
      raw
    end
  end
end

processor.project({q: "search", sort_by: "name"})
processor.call([], {q: "search", sort_by: "name"})
