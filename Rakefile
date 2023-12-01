# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec)

begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new

  RuboCop::RakeTask.new("rubocop:md") do |task|
    task.options << %w[-c .rubocop-md.yml]
  end
rescue LoadError
  task(:rubocop) {}
  task("rubocop:md") {}
end

task :steep do
  # Steep doesn't provide Rake integration yet,
  # but can do that ourselves
  require "steep"
  require "steep/cli"

  Steep::CLI.new(argv: ["check", "--severity-level=error"], stdout: $stdout, stderr: $stderr, stdin: $stdin).run.tap do |exit_code|
    exit(exit_code) unless exit_code.zero?
  end
end

namespace :steep do
  task :stats do
    exec "bundle exec steep stats --log-level=fatal --format=table"
  end
end

namespace :spec do
  desc "Run RSpec with RBS runtime tester enabled"
  task :rbs do
    rspec_args = ARGV.join.split("--", 2).then { (_1.size == 2) ? _1.last : nil }
    sh <<~COMMAND
      RACK_ENV=test \
      RBS_TEST_LOGLEVEL=error \
      RBS_TEST_TARGET="Rubanok::*" \
      RUBYOPT="-rrbs/test/setup" \
      bundle exec rspec \
      #{rspec_args}
    COMMAND
  end
end

task default: %w[steep rubocop rubocop:md spec spec:rbs]
