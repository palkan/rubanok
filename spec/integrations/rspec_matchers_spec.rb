# frozen_string_literal: true

require "spec_helper"

class RspecPlane < Rubanok::Plane
end

class AnotherRspecPlane < Rubanok::Plane
end

describe "Rubanok RSpec matchers" do
  describe "#have_rubanok_processed" do
    specify "matches processor class" do
      expect do
        RspecPlane.call([], {type: "array"})
      end.to have_rubanok_processed.with(RspecPlane)
    end

    specify "matches data class and processor class" do
      expect do
        RspecPlane.call([], {type: "array"})
      end.to have_rubanok_processed(Array).with(RspecPlane)
    end

    specify "doesn't match data class" do
      expect do
        expect { RspecPlane.call([], {type: "array"}) }
          .to have_rubanok_processed(Hash).with(RspecPlane)
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    end

    specify "doesn't match processor" do
      expect do
        expect { AnotherRspecPlane.call([], {type: "array"}) }
          .to have_rubanok_processed(Array).with(RspecPlane)
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    end

    specify "when negated" do
      expect do
        expect { RspecPlane.call([], {type: "array"}) }
          .not_to have_rubanok_processed.with(RspecPlane)
      end.to raise_error(RSpec::Expectations::ExpectationNotMetError)
    end
  end

  describe "#have_planished" do
    specify "matches plane class" do
      expect do
        RspecPlane.call([], {type: "array"})
      end.to have_planished.with(RspecPlane)
    end
  end
end
