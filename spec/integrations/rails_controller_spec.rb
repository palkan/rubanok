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

module PostsControllerBehaviour
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

class PostsController < ActionController::Base
  include PostsControllerBehaviour
end

if defined?(ActionController::API)
  class PostsApiController < ActionController::API
    include PostsControllerBehaviour

    def implicit_rubanok_class
      "#{controller_name.sub(/api/i, "").classify}Processor".safe_constantize
    end

    def implicit_plane_class
      "#{controller_name.sub(/api/i, "").classify}Plane".safe_constantize
    end
  end
end

describe "Rails controllers integration" do
  include RSpec::Rails::ControllerExampleGroup

  routes { SharedTestRoutes }

  shared_examples "rubanok controller" do
    describe "#planish" do
      let(:data) { JSON.parse(response.body) }

      # ?? Rails 4.2 failes with ThreadError: already initialized
      before do
        @response.define_singleton_method(:recycle!) {}
      end

      specify "implicit rubanok" do
        get :implicit, params: {type: "sports"}

        expect(data.size).to eq 2
      end

      specify "implicit rubanok with matching" do
        get :implicit, params: {sort_by: "type", sort: "desc"}

        expect(data.size).to eq 3
        expect(data.first["type"]).to eq "lifestyle"
      end

      specify "implicit plane" do
        get :implicit_plane, params: {type: "sports"}

        expect(data.size).to eq 2
      end

      specify "explicit" do
        get :explicit, params: {filter: {type: "sports"}}

        expect(data.size).to eq 1
        expect(data.first["id"]).to eq 25
      end

      specify "#rubanok_scope" do
        get :scoped, params: {type: "sports", date: "2019-08-22", sort_by: "id", sort: "desc", one_more: "key"}

        expect(data).to eq(
          {
            "type" => "sports",
            "sort_by" => "id",
            "sort" => "desc"
          }
        )
      end

      specify "#planish_scope" do
        get :scoped_plane, params: {date: "2019-08-22", sort_by: "id", one_more: "key"}

        expect(data).to eq(
          {
            "sort_by" => "id"
          }
        )
      end
    end
  end

  describe PostsController do
    include_examples "rubanok controller"
  end

  if defined?(PostsApiController)
    describe PostsApiController do
      include_examples "rubanok controller"
    end
  end
end
