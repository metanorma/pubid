# frozen_string_literal: true

require "rake"
require "fileutils"
require "rubocop/rake_task"
require "bundler/gem_tasks"

# Load additional rake tasks (docs, export)
Dir["lib/tasks/*.rake"].each { |f| import f }

# Single source of truth for the gem version.
def current_version
  require_relative "lib/pubid/version"
  Pubid::VERSION
end

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------
namespace :test do
  desc "Run all unit specs"
  task :all do
    sh "bundle exec rspec spec/pubid spec/pubid_spec.rb"
  end

  desc "Run integration tests"
  task :integration do
    sh "bundle exec rspec spec/integration"
  end

  # A convenience entry point, not an extra gate: the spec file lives under
  # spec/pubid, so `test:all` already loads it — it just self-skips unless
  # PUBID_IETF_CORPUS is set. Setting that variable therefore also adds the
  # (~100s) corpus run to a plain `rake`.
  desc "IETF corpus round-trip (needs PUBID_IETF_CORPUS=<dir containing " \
       "relaton-data-{rfcs,rfcsubseries,ids}>)"
  task :corpus_ietf do
    sh "bundle exec rspec spec/pubid/ietf/corpus_round_trip_spec.rb"
  end

  # Same shape as :corpus_ietf above — self-skips unless PUBID_IANA_CORPUS is
  # set, so it costs the default suite nothing.
  desc "IANA corpus round-trip (needs PUBID_IANA_CORPUS=<dir containing " \
       "relaton-data-iana>)"
  task :corpus_iana do
    sh "bundle exec rspec spec/pubid/iana/corpus_round_trip_spec.rb"
  end
end

desc "Run the full spec suite (alias of test:all)"
task spec: "test:all"

# ---------------------------------------------------------------------------
# RuboCop
# ---------------------------------------------------------------------------
RuboCop::RakeTask.new(:rubocop)

namespace :rubocop do
  desc "Run RuboCop (alias of :rubocop)"
  task all: :rubocop
end

# ---------------------------------------------------------------------------
# Version
#
# The gem version lives in lib/pubid/version.rb (Pubid::VERSION).
# ---------------------------------------------------------------------------
namespace :version do
  desc "Show current version"
  task :show do
    puts "Version: #{current_version}"
  end

  desc "Bump version (major|minor|patch) in lib/pubid/version.rb"
  task :bump, [:type] do |_t, args|
    bump_type = args[:type] || "patch"
    unless %w[major minor patch].include?(bump_type)
      abort "Error: bump type must be major, minor, or patch"
    end

    version_file = "lib/pubid/version.rb"
    content = File.read(version_file)
    old_string = content[/VERSION\s*=\s*"([^"]+)"/, 1]
    abort "Error: could not find VERSION in #{version_file}" unless old_string

    # Bump the numeric release portion, dropping any pre-release suffix.
    major, minor, patch = old_string.split(".").first(3).map(&:to_i)
    new_version =
      case bump_type
      when "major" then "#{major + 1}.0.0"
      when "minor" then "#{major}.#{minor + 1}.0"
      when "patch" then "#{major}.#{minor}.#{patch + 1}"
      end

    File.write(version_file, content.sub(old_string, new_version))
    puts "Bumped version from #{old_string} to #{new_version}"
  end
end

# ---------------------------------------------------------------------------
# Default
# ---------------------------------------------------------------------------
task default: ["test:all", "test:integration"]

# Validation tasks for V2 implementations
namespace :validation do
  desc "Run classification for all V2 flavors"
  task :classify_all do
    puts "Running classification for all V2 flavors..."
    puts
    Dir.chdir("spec/fixtures") { ruby "run_classify.rb all" }
  end

  desc "Run classification for a specific flavor"
  task :classify, [:flavor] do |_t, args|
    flavor = args[:flavor] || raise("Usage: rake validation:classify[flavor]")
    Dir.chdir("spec/fixtures") { ruby "run_classify.rb #{flavor}" }
  end

  desc "Show validation summary for all flavors"
  task :report do
    require_relative "spec/fixtures/classify_fixtures"
    require_relative "lib/pubid"

    # All V2 flavors with SUMMARY.txt
    results = []

    Dir.glob("spec/fixtures/*/SUMMARY.txt").each do |summary_file|
      flavor = File.basename(File.dirname(summary_file))

      # Read SUMMARY.txt to extract stats
      content = File.read(summary_file)

      if content =~ /Total: (\d+)/
        total = $1.to_i
      else
        next
      end

      if content =~ /Pass: (\d+) \(([\d.]+)%\)/
        pass = $1.to_i
        percentage = $2.to_f
      else
        next
      end

      fail = if content =~ /Fail: (\d+)/
               $1.to_i
             else
               total - pass
             end

      results << {
        flavor: flavor,
        pass: pass,
        fail: fail,
        total: total,
        percentage: percentage,
      }
    end

    # Sort by percentage descending, then by flavor name
    results.sort_by! { |r| [-r[:percentage], r[:flavor]] }

    # Display pretty report
    puts
    puts "=" * 85
    puts "#{' ' * 22}PubID V2 Validation Report"
    puts "=" * 85
    puts
    puts "#{'Flavor'.ljust(12)}#{'Pass'.rjust(10)}#{'Fail'.rjust(8)}#{'Total'.rjust(10)}#{'Percentage'.rjust(15)}  Status"
    puts "-" * 85

    results.each do |r|
      status = if r[:percentage] == 100.0
                 "🎉 Perfect"
               elsif r[:percentage] >= 99.0
                 "✨ Excellent"
               elsif r[:percentage] >= 95.0
                 "✅ Very Good"
               elsif r[:percentage] >= 90.0
                 "👍 Good"
               elsif r[:percentage] >= 85.0
                 "📈 Enhanced"
               else
                 "⚠️  Partial"
               end

      puts r[:flavor].upcase.ljust(12) +
        r[:pass].to_s.rjust(10) +
        r[:fail].to_s.rjust(8) +
        r[:total].to_s.rjust(10) +
        "#{r[:percentage]}%".rjust(15) +
        "  #{status}"
    end

    puts "-" * 85
    total_pass = results.sum { |r| r[:pass] }
    total_fail = results.sum { |r| r[:fail] }
    total_all = results.sum { |r| r[:total] }
    overall_pct = ((total_pass.to_f / total_all) * 100).round(2)

    puts "TOTAL".ljust(12) +
      total_pass.to_s.rjust(10) +
      total_fail.to_s.rjust(8) +
      total_all.to_s.rjust(10) +
      "#{overall_pct}%".rjust(15)
    puts "=" * 85
    puts
    puts "Flavors validated: #{results.length}"
    puts "Perfect (100%): #{results.count { |r| r[:percentage] == 100.0 }}"
    puts "Excellent (99%+): #{results.count do |r|
      r[:percentage] >= 99.0 && r[:percentage] < 100.0
    end}"
    puts "Good (90%+): #{results.count do |r|
      r[:percentage] >= 90.0 && r[:percentage] < 99.0
    end}"
    puts
    puts "Legend:"
    puts "  🎉 Perfect:   100%     - All identifiers validated"
    puts "  ✨ Excellent: 99-100%  - Production excellent quality"
    puts "  ✅ Very Good: 95-99%   - Production ready"
    puts "  👍 Good:      90-95%   - High quality"
    puts "  📈 Enhanced:  85-90%   - Enhanced implementation"
    puts "  ⚠️  Partial:   <85%     - Needs enhancement"
    puts
    puts "Commands:"
    puts "  rake validation:classify_all     - Classify all flavors"
    puts "  rake validation:classify[flavor] - Classify specific flavor"
    puts "  rake validation:report           - Show this report"
    puts
  end
end
