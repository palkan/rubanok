# frozen_string_literal: true

require_relative "./controller_helper"

class RejectPlane < Rubanok::Plane
  map :type do |type:|
    raw.reject { |item| item[:type] == type }
  end
end

class PostsPlane < Rubanok::Plane
  map :type do |type:|
    raw.select { |item| item[:type] == type }
  end

  match :sort_by, :sort, activate_on: :sort_by do
    having "type" do |sort: "asc"|
      coef = sort == "asc" ? 1 : -1
      raw.sort do |a, b|
        next 0 if a[:type] == b[:type]
        coef * (a[:type] == "sports" ? -1 : 1)
      end
    end
  end
end

PostsProcessor = PostsPlane

if ActionPack.version.release < Gem::Version.new("5")
  using(Module.new do
    refine Hash do
      def to_params
        self
      end
    end
  end)
else
  using(Module.new do
    refine Hash do
      def to_params
        {params: self}
      end
    end
  end)
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
    data = rubanok_process(
      FAKE_DATA,
      params.require(:filter),
      with: ::RejectPlane
    )
    render json: data
  end

  def implicit_plane
    data = planish(FAKE_DATA)
    render json: data
  end

  def implicit
    data = rubanok_process(FAKE_DATA)
    render json: data
  end

  def scoped
    render json: rubanok_scope(params.permit(:type, :sort, :sort_by, :date))
  end

  def scoped_plane
    render json: planish_scope
  end
end

describe PostsController do
  include RSpec::Rails::ControllerExampleGroup

  routes { SharedTestRoutes }

  describe "#planish" do
    let(:data) { JSON.parse(response.body) }

    # ?? Rails 4.2 failes with ThreadError: already initialized
    before do
      @response.define_singleton_method(:recycle!) {}
    end

    specify "implicit rubanok" do
      get :implicit, {type: "sports"}.to_params

      expect(data.size).to eq 2
    end

    specify "implicit rubanok with matching" do
      get :implicit, {sort_by: "type", sort: "desc"}.to_params

      expect(data.size).to eq 3
      expect(data.first["type"]).to eq "lifestyle"
    end

    specify "implicit plane" do
      get :implicit_plane, {type: "sports"}.to_params

      expect(data.size).to eq 2
    end

    specify "explicit" do
      get :explicit, {filter: {type: "sports"}}.to_params

      expect(data.size).to eq 1
      expect(data.first["id"]).to eq 25
    end

    specify "#rubanok_scope" do
      get :scoped, {type: "sports", date: "2019-08-22", sort_by: "id", sort: "desc", one_more: "key"}.to_params

      expect(data).to eq(
        {
          "type" => "sports",
          "sort_by" => "id",
          "sort" => "desc"
        }
      )
    end

    specify "#planish_scope" do
      get :scoped_plane, {date: "2019-08-22", sort_by: "id", one_more: "key"}.to_params

      expect(data).to eq(
        {
          "sort_by" => "id"
        }
      )
    end
  end
end
