# frozen_string_literal: true

require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

require 'tmpdir'

# Isolate persisted tooling baselines from the real ~/.local/share during specs.
ENV['XDG_DATA_HOME'] = Dir.mktmpdir('rview-spec-data')

require 'rview'

RSpec.configure do |config|
  # A partial run (single file, single example, ...) produces a misleading
  # coverage total: write it to a scratch dir so coverage/.last_run.json —
  # read by the rview tooling box — only reflects full-suite runs.
  config.before(:suite) do
    all_spec_files = Dir[File.expand_path('**/*_spec.rb', __dir__)]
    files_to_run = RSpec.configuration.files_to_run.map { |f| File.expand_path(f) }.sort
    SimpleCov.coverage_dir 'tmp/coverage-partial' unless files_to_run == all_spec_files
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.warnings = true
  config.order = :random
  Kernel.srand config.seed
end
