# typed: false
# frozen_string_literal: true

describe "Plane.match" do
  let(:input) do
    [
      {
        name: "Dexter",
        age: "53",
        occupation: "vocal"
      },
      {
        name: "Noodles",
        age: "55",
        occupation: "guitar"
      },
      {
        name: "Ron",
        age: "47",
        occupation: "drums",
        status: "past"
      },
      {
        name: "Greg",
        age: "54",
        occupation: "bas"
      },
      {
        name: "Pete",
        age: "44",
        occupation: "drums",
        status: "active"
      }
    ].freeze
  end

  let(:params) { {} }

  subject { plane.call(input, params) }

  context "single argument" do
    let(:plane) do
      Class.new(Rubanok::Plane) do
        match :status do
          having "active" do
            raw.select { |item| item[:status] == "active" || !item.key?(:status) }
          end

          having "past" do
            raw.select { |item| item[:status] == "past" }
          end
        end
      end
    end

    specify "no matching params" do
      expect(subject).to eq input
    end

    specify "with matching param and value" do
      params[:status] = "active"
      expect(subject.size).to eq 4
    end

    specify "with non-matching value" do
      params[:status] = "unknown"
      expect(subject.size).to eq 5
    end

    specify "when key is a string" do
      params["status"] = "past"
      expect(subject.size).to eq 1
      expect(subject.first[:name]).to eq "Ron"
    end

    context "with default clause" do
      let(:plane) do
        Class.new(Rubanok::Plane) do
          match :status do
            having "past" do
              raw.select { |item| item[:status] == "past" }
            end

            default do |status:|
              []
            end
          end
        end
      end

      specify "when no matching value" do
        params["status"] = "unknown"
        expect(subject).to eq []
      end
    end

    context "with default clause and activate_always" do
      let(:plane) do
        Class.new(Rubanok::Plane) do
          match :status, activate_always: true do
            having "past" do
              raw.select { |item| item[:status] == "past" }
            end

            default do |status: "none"|
              raw.select { |item| item[:status].nil? }
            end
          end
        end
      end

      specify "with default value" do
        expect(subject.size).to eq 3
      end
    end
  end

  context "multiple fields" do
    let(:plane) do
      Class.new(Rubanok::Plane) do
        match :sort_by, :sort, activate_on: :sort_by do
          having "status", "asc" do
            raw.sort do |a, b|
              next 0 if a[:status] == b[:status]

              a[:status].nil? || a[:status] == "active" ? -1 : 1
            end
          end

          having "status", "desc" do
            raw.sort do |a, b|
              next 0 if a[:status] == b[:status]
              next -1 if a[:status].nil?
              next 1 if b[:status].nil?

              a[:status] == "past" ? -1 : 1
            end
          end

          having "name" do |sort: "asc"|
            sign = sort == "asc" ? 1 : -1

            raw.sort do |a, b|
              a[:name] == "Dexter" ? -1 : sign * (a[:name] <=> b[:name])
            end
          end

          default do |sort_by:, sort: "asc"|
            return [] unless valid_sort_field?(sort_by)

            sign = sort == "asc" ? 1 : -1

            sort_by = sort_by.to_sym

            raw.sort { |a, b| sign * (a[sort_by] <=> b[sort_by]) }
          end
        end

        def valid_sort_field?(field)
          %w[age].include?(field)
        end
      end
    end

    let(:names) { subject.map { |item| item[:name] } }

    specify "no matches" do
      expect(subject).to eq(input)
    end

    specify "with both params match" do
      params[:sort_by] = "status"
      params[:sort] = "asc"

      expect(names).to eq(
        %w[Dexter Noodles Greg Pete Ron]
      )
    end

    specify "when second clause match" do
      params[:sort_by] = "status"
      params[:sort] = "desc"

      expect(names).to eq(
        %w[Dexter Noodles Greg Ron Pete]
      )
    end

    specify "when only one param present" do
      params[:sort_by] = "name"

      expect(names).to eq(
        %w[Dexter Greg Noodles Pete Ron]
      )
    end

    specify "when both params present for one param matching clause" do
      params[:sort_by] = "name"
      params[:sort] = "desc"

      expect(names).to eq(
        %w[Dexter Ron Pete Noodles Greg]
      )
    end

    specify "when default clause match" do
      params[:sort_by] = "age"
      params[:sort] = "desc"

      expect(names).to eq(
        %w[Noodles Greg Dexter Ron Pete]
      )
    end

    specify "calling instance method" do
      params[:sort_by] = "salary"
      params[:sort] = "desc"

      expect(names).to eq([])
    end
  end
end
