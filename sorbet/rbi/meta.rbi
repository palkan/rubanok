# typed: strong

module Rubanok::DSL::Matching
  sig { returns(T.untyped) }
  def raw
  end

  sig { params(method_name: String, data: T.untyped).returns(T.untyped) }
  def apply_rule!(method_name, data)
  end
end
