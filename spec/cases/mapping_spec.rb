# typed: false
# frozen_string_literal: true

describe "Plane.map" do
  let(:input) do
    [
      {
        name: "Kurt",
        age: "51",
        occupation: "guitar"
      },
      {
        name: "Kris",
        age: "53",
        occupation: "bas"
      },
      {
        name: "Dave",
        age: "49",
        occupation: "drums"
      }
    ].freeze
  end

  let(:params) { {} }

  subject { plane.call(input, params) }

  context "single argument" do
    let(:plane) do
      Class.new(Rubanok::Plane) do
        map :q do |q:|
          raw.select { |item| item[:name].include?(q) }
        end
      end
    end

    specify "no matching params" do
      expect(subject).to eq input
    end

    specify "with matching param" do
      params[:q] = "rt"
      expect(subject.size).to eq 1
      expect(subject.first[:name]).to eq "Kurt"
    end

    specify "with multiple matches" do
      params[:q] = "K"
      expect(subject.size).to eq 2
      expect(subject.first[:name]).to eq "Kurt"
      expect(subject.last[:name]).to eq "Kris"
    end

    specify "when key is a string" do
      params["q"] = "Da"
      expect(subject.size).to eq 1
      expect(subject.first[:name]).to eq "Dave"
    end

    context "multiple maps" do
      let(:plane) do
        Class.new(Rubanok::Plane) do
          map :q do |q:|
            raw.select { |item| item[:name].include?(q) }
          end

          map :young do |_|
            raw.select { |item| item[:age].to_i < 50 }
          end
        end
      end

      specify "no matches" do
        params[:q] = "K"
        params[:young] = "1"

        expect(subject).to eq([])
      end

      specify "with match" do
        params[:q] = "ave"
        params[:young] = "true"

        expect(subject.size).to eq 1
        expect(subject.first[:name]).to eq "Dave"
      end
    end
  end

  context "multiple fields + activate_always" do
    let(:plane) do
      Class.new(Rubanok::Plane) do
        map :page, :per_page, activate_always: true do |page: 1, per_page: 2|
          raw[((page - 1) * per_page)..(page * per_page - 1)]
        end
      end
    end

    specify "no matches" do
      expect(subject.size).to eq 2
      expect(subject.first[:name]).to eq "Kurt"
      expect(subject.last[:name]).to eq "Kris"
    end

    specify "with one param match" do
      params[:page] = 2

      expect(subject.size).to eq 1
      expect(subject.first[:name]).to eq "Dave"
    end

    specify "with both params match" do
      params[:page] = 2
      params[:per_page] = 1

      expect(subject.size).to eq 1
      expect(subject.first[:name]).to eq "Kris"
    end
  end

  context "multiple fields + activate_on" do
    let(:plane) do
      Class.new(Rubanok::Plane) do
        map :page, :per_page, activate_on: [:page] do |page:, per_page: 2|
          raw[((page - 1) * per_page)..(page * per_page - 1)]
        end
      end
    end

    specify "no matches" do
      expect(subject.size).to eq 3
    end

    specify "with one param match" do
      params[:page] = 1

      expect(subject.size).to eq 2
      expect(subject.first[:name]).to eq "Kurt"
      expect(subject.last[:name]).to eq "Kris"
    end

    specify "with both params match" do
      params[:page] = 3
      params[:per_page] = 1

      expect(subject.size).to eq 1
      expect(subject.first[:name]).to eq "Dave"
    end
  end

  context "ignore_empty_values" do
    let(:plane) do
      Class.new(Rubanok::Plane) do
        map :type do |type:|
          raw.select { |item| item[:occupation] == type }
        end
      end
    end

    let(:params) { {type: ""} }

    around do |ex|
      was_value = Rubanok.ignore_empty_values
      ex.run
      Rubanok.ignore_empty_values = was_value
    end

    specify "ignore_empty_values=true" do
      Rubanok.ignore_empty_values = true
      expect(subject).to eq(input)
    end

    specify "ignore_empty_values=false" do
      Rubanok.ignore_empty_values = false
      expect(subject).to eq([])
    end
  end
end
