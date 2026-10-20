# frozen_string_literal: true

require "benchmark"

namespace :benchmark do
  desc "Parse throughput per flavor over the testsuite corpus " \
       "(PUBID_TESTSUITE_PATH=<dir>, FLAVOR=ieee,iso, LIMIT=N)"
  task :corpus do
    require "pubid"

    corpus_dir = ENV["PUBID_TESTSUITE_PATH"] ||
      File.expand_path("../../../pubid-testsuite/tests", __dir__)
    unless Dir.exist?(corpus_dir)
      abort "corpus not found at #{corpus_dir} — set PUBID_TESTSUITE_PATH " \
            "to a pubid-testsuite checkout's tests/ directory"
    end

    limit = ENV["LIMIT"]&.to_i
    dir_to_flavor = { "tgpp" => "3gpp" }
    flavors = if ENV["FLAVOR"]
                ENV["FLAVOR"].split(",").map(&:strip)
              else
                Dir.children(corpus_dir)
                  .select { |name| File.directory?(File.join(corpus_dir, name)) && !name.start_with?("_") }
                  .sort
              end

    Pubid.eager_load_flavors!

    rows = flavors.filter_map do |dir_name|
      flavor = (dir_to_flavor[dir_name] || dir_name).to_sym
      mod = Pubid::Registry.get(flavor)
      next unless mod

      cases = Pubid::Conformance::Corpus.cases(dir_name, corpus_dir)
      inputs = cases.filter_map { |c| c.representations&.human || c.input }
      inputs = inputs.first(limit) if limit && limit.positive?
      next if inputs.empty?

      failures = 0
      elapsed = ::Benchmark.realtime do
        inputs.each do |input|
          mod.parse(input)
        rescue StandardError
          failures += 1
        end
      end
      rate = elapsed.zero? ? 0.0 : inputs.size / elapsed
      { flavor: dir_name, cases: inputs.size, failures: failures,
        seconds: elapsed, rate: rate }
    end

    rows.sort_by! { |row| -row[:rate] }
    total_cases = rows.sum { |row| row[:cases] }
    total_seconds = rows.sum { |row| row[:seconds] }

    puts format("%-14s %8s %8s %10s %12s", "flavor", "cases", "failed", "seconds", "parses/sec")
    rows.each do |row|
      puts format("%-14s %8d %8d %10.3f %12.1f", row[:flavor], row[:cases],
                  row[:failures], row[:seconds], row[:rate])
    end
    puts format("%-14s %8d %8s %10.3f %12.1f", "TOTAL", total_cases, "",
                total_seconds, total_seconds.zero? ? 0.0 : total_cases / total_seconds)
    puts
    puts "ruby #{RUBY_VERSION}; parsanol #{Gem.loaded_specs['parsanol']&.version}; " \
         "pubid #{Pubid::VERSION}"
  end
end
