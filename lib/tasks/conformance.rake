# frozen_string_literal: true

require "yaml"
require "fileutils"

namespace :conformance do
  desc "Generate the neutral corpus from ground-truth fixtures"
  task :generate, [:flavor] do |_t, args|
    require "pubid"
    require "pubid/conformance"
    flavor = args[:flavor] || "iso"
    output_dir = File.expand_path("../../conformance/#{flavor}", __dir__)
    FileUtils.mkdir_p(output_dir)
    results = Pubid::Conformance::Generator.new(flavor)
      .generate(output_dir: output_dir)
    puts "#{flavor}: #{results[:files]} type files, #{results[:cases]} " \
         "cases, #{results[:negative]} negative, #{results[:debt]} debt, " \
         "#{results[:roundtrip_failures]} roundtrip-failures"
  end

  desc "Run the neutral corpus against this implementation"
  task :run do
    require "pubid"
    require "pubid/conformance"
    failures = Pubid::Conformance::Runner.new.run.flatten
    puts "TOTAL failures: #{failures.size}"
    exit(failures.empty? ? 0 : 1)
  end
end
