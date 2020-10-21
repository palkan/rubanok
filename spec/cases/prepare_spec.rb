# frozen_string_literal: true

describe "Plane.prepare_raw" do
  let(:input) { {} }
  let(:params) { {} }

  let(:plane) do
    Class.new(Rubanok::Plane) do
      prepare do
        next if raw&.dig(:index)

        {index: "test"}
      end

      map :q do |q:|
        raw[:query] = q
        raw
      end
    end
  end

  subject { plane.call(input, params) }

  specify "no matching params" do
    expect(subject).to eq input
  end

  specify "with matching param" do
    params[:q] = "rt"
    expect(subject).to eq(index: "test", query: "rt")
  end

  specify "when no input specified" do
    params[:q] = "qwe"
    expect(plane.call(params)).to eq(index: "test", query: "qwe")
  end
end
