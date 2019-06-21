source "https://rubygems.org"

# Specify your gem's dependencies in rubanok.gemspec
gemspec

gem "pry-byebug", platform: :mri
gem "simplecov"
gem "sorbet"

local_gemfile = 'Gemfile.local'

if File.exist?(local_gemfile)
  eval(File.read(local_gemfile)) # rubocop:disable Security/Eval
end
