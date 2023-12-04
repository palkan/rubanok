# frozen_string_literal: true

describe "Plane.process" do
  let(:input) do
    [
      {
        name: "Dexter",
        occupation: "vocal",
        status: "forever"
      },
      {
        name: "Noodles",
        occupation: "guitar",
        status: "forever"
      },
      {
        name: "Ron",
        occupation: "drums",
        status: "past"
      },
      {
        name: "Greg",
        occupation: "bas",
        status: "past"
      },
      {
        name: "Todd",
        occupation: "bas",
        status: "active"
      }
    ].freeze
  end

  let(:params) { {} }

  subject { plane.call(input, params) }

  context "single argument" do
    let(:plane) do
      Class.new(Rubanok::Plane) do
        process :filter do
          map :status do |status:|
            raw.select { _1[:status] == status }
          end

          map :occupation do |occupation:|
            raw.select { _1[:occupation] == occupation }
          end
        end
      end
    end

    specify "no matching params" do
      expect(subject).to eq input
    end

    specify "with matching param and value (status)" do
      params[:filter] = {status: "past"}

      expect(subject).to match_array(
        [
          {
            name: "Ron",
            occupation: "drums",
            status: "past"
          },
          {
            name: "Greg",
            occupation: "bas",
            status: "past"
          }
        ]
      )
    end

    specify "with matching param and value (occupation)" do
      params[:filter] = {occupation: "bas"}

      expect(subject).to match_array([
        {
          name: "Greg",
          occupation: "bas",
          status: "past"
        },
        {
          name: "Todd",
          occupation: "bas",
          status: "active"
        }
      ])
    end
  end

  context "nested process" do
    let(:plane) do
      Class.new(Rubanok::Plane) do
        process :filter do
          map :status do |status:|
            raw
          end

          process :name do
            map :dexter do |*|
              raw.select { _1[:name] == "Dexter" }
            end

            map :noodles do |*|
              raw.select { _1[:name] == "Noodles" }
            end
          end
        end
      end
    end

    specify do
      params[:filter] = {name: {"noodles" => "1"}}

      expect(subject).to match_array([
        {
          name: "Noodles",
          occupation: "guitar",
          status: "forever"
        }
      ])
    end

    specify "when nested value is not a Hash-like" do
      params[:filter] = {name: "noodles"}

      expect(subject).to eq input
    end
  end
end
