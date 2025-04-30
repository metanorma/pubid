# frozen_string_literal: true

require "bundler/setup"
require "rspec/matchers"

Dir["./spec/support/**/*.rb"].sort.each { |f| require f }

require_relative "../lib/pubid-iso"

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
end
