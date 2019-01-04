# frozen_string_literal: true

require_relative "./controller_helper"

class RejectPlane < Rubanok::Plane
  map :type do |type|
    data.reject { |item| item[:type] == type }
  end
end

class PostPlane < Rubanok::Plane
  map :type do |type|
    data.select { |item| item[:type] == type }
  end
end

class PostsController < ActionController::Base
  FAKE_DATA = [
    {
      id: 12,
      type: "sports",
      title: "Liverpool vs. Manchester United"
    },
    {
      id: 25,
      type: "lifestyle",
      title: "How to feed a kitten"
    },
    {
      id: 4,
      type: "sports",
      title: "Roach race finals"
    }
  ].freeze

  def explicit
    data = planish(
      FAKE_DATA,
      params,
      with: ::RejectPlane
    )
    render text: data.to_json
  end

  def implicit
    data = planish(FAKE_DATA)
    render text: data.to_json
  end
end

describe "Rails controller integration" do
  include RSpec::Rails::RailsExampleGroup
  include ActionController::TestCase::Behavior

  before { @routes = SharedTestRoutes }

  tests PostsController

  describe "#planish" do
    let(:data) { JSON.parse(response.body) }

    specify "implicit plane" do
      get :implicit, params: {type: "sports"}

      epxect(data.size).to eq 2
    end
  end

  describe "#have_planished"
end
