# frozen_string_literal: true

require "bundler/setup"
require "rspec/matchers"

# Load all gems for integration testing
Dir["./gems/*/lib/*"].each do |gem_lib|
  gem_name = File.basename(gem_lib, ".rb")
  require gem_name if gem_name.start_with?("pubid")
end

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on Module and main
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
