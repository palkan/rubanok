# frozen_string_literal: true

describe Rubanok::Processor do
  describe ".project" do
    let(:processor) do
      Class.new(Rubanok::Processor) do
        map :q do |q:|
          raw
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
    end

    it "returns only processable params" do
      expect(
        processor.project(a: "x", filter: "active", q: "daaron", sort_by: "id", sort: "desc")
      ).to eq(
        {
          q: "daaron",
          sort_by: "id",
          sort: "desc"
        }
      )
    end

    it "doesn't return keys not present in params" do
      expect(
        processor.project(a: "x", sort_by: "id", sort: "desc")
      ).to eq(
        {
          sort_by: "id",
          sort: "desc"
        }
      )
    end

    it "doesn't return defaults" do
      expect(processor.project(sort_by: "name")).to eq(
        {
          sort_by: "name"
        }
      )
    end
  end
end
