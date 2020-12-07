# frozen_string_literal: true

# Steepfile
target :lib do
  # Load signatures from sig/ folder
  signature "sig"
  # Check only files from lib/ folder
  check "lib"

  # We don't want to type check Rails/RSpec related code
  # (because we don't have RBS files for it)
  ignore "lib/rubanok/rails/*.rb"
  ignore "lib/rubanok/railtie.rb"
  ignore "lib/rubanok/rspec.rb"

  # We use Set standard library; its signatures
  # come with RBS, but we need to load them explicitly
  library "set"
end
