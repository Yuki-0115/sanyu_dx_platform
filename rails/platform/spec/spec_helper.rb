# frozen_string_literal: true

RSpec.configure do |config|
  # rspec-expectations config
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  # rspec-mocks config
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  # Shared context metadata behavior
  config.shared_context_metadata_behavior = :apply_to_host_groups

  # This option will default to `:apply_to_host_groups` in RSpec 4
  config.filter_run_when_matching :focus

  # Allows RSpec to persist some state between runs
  config.example_status_persistence_file_path = "spec/examples.txt"

  # Limits the available syntax to the non-monkey patched syntax
  config.disable_monkey_patching!

  # Print the 10 slowest examples and example groups
  config.profile_examples = 10 if config.files_to_run.one?

  # Run specs in random order
  config.order = :random

  # Seed global randomization
  Kernel.srand config.seed
end
