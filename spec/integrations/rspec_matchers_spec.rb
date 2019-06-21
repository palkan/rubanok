# typed: false
# frozen_string_literal: true

require "spec_helper"

class RspecPlane < Rubanok::Plane
end

class AnotherRspecPlane < Rubanok::Plane
end

describe "Rubanok RSpec matchers" do
  describe "#have_planished" do
    specify "matches plane class" do
      expect do
        RspecPlane.call([], {type: "array"})
      end.to have_planished.with(RspecPlane)
    end

    specify "matches data class and plane class" do
      expect do
        RspecPlane.call([], {type: "array"})
      end.to have_planished(Array).with(RspecPlane)
    end

    specify "doesn't match data class" do
      expect do
        expect { RspecPlane.call([], {type: "array"}) }
          .to have_planished(Hash).with(RspecPlane)
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    end

    specify "doesn't match plane" do
      expect do
        expect { AnotherRspecPlane.call([], {type: "array"}) }
          .to have_planished(Array).with(RspecPlane)
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    end

    specify "when negated" do
      expect do
        expect { RspecPlane.call([], {type: "array"}) }
          .not_to have_planished.with(RspecPlane)
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    end
  end
end
