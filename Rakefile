require "rake"
require "fileutils"

# Get list of all gems
GEMS = if Dir.exist?("gems")
         Dir["gems/*/"].map do |dir|
           File.basename(dir)
         end.freeze
       else
         [].freeze
       end

# Helper to convert gem name to namespace (pubid-core -> pubid_core)
def gem_to_namespace(gem_name)
  gem_name.tr("-", "_").to_sym
end

# Helper to run command in gem directory
def in_gem_dir(gem_name, &block)
  Dir.chdir("gems/#{gem_name}", &block)
end

# Define tasks for each gem
GEMS.each do |gem_name|
  namespace_name = gem_to_namespace(gem_name)

  namespace :test do
    desc "Run specs for #{gem_name}"
    task namespace_name do
      puts "Testing #{gem_name}..."
      success = Bundler.with_unbundled_env do
        system("cd gems/#{gem_name} && rm -f Gemfile.lock && bundle && bundle exec rake")
      end
      raise "Test failed for #{gem_name}" unless success
    end
  end

  namespace :build do
    desc "Build #{gem_name}"
    task namespace_name do
      puts "Building #{gem_name}..."
      in_gem_dir(gem_name) { sh "gem build *.gemspec" }
    end
  end

  namespace :install do
    desc "Install #{gem_name} locally"
    task namespace_name => "build:#{namespace_name}" do
      puts "Installing #{gem_name}..."
      in_gem_dir(gem_name) do
        gem_file = Dir["*.gem"].first
        sh "gem install #{gem_file}"
      end
    end
  end

  namespace :clean do
    desc "Clean built files for #{gem_name}"
    task namespace_name do
      puts "Cleaning #{gem_name}..."
      in_gem_dir(gem_name) do
        FileUtils.rm_f(Dir["*.gem"])
      end
    end
  end

  namespace :release do
    desc "Release #{gem_name} to RubyGems"
    task namespace_name => "build:#{namespace_name}" do
      puts "Releasing #{gem_name}..."
      in_gem_dir(gem_name) do
        gem_file = Dir["*.gem"].first
        sh "gem push #{gem_file}"
      end
    end
  end

  namespace :rubocop do
    desc "Run RuboCop for #{gem_name}"
    task namespace_name do
      puts "Running RuboCop for #{gem_name}..."
      in_gem_dir(gem_name) { sh "bundle exec rubocop" }
    end
  end
end

# Aggregate tasks
namespace :test do
  desc "Run all gem specs"
  task :all do
    GEMS.each do |gem_name|
      Rake::Task["test:#{gem_to_namespace(gem_name)}"].invoke
    end
  end

  desc "Run integration tests"
  task :integration do
    puts "Running integration tests..."
    sh "bundle exec rspec spec/integration"
  end
end

namespace :build do
  desc "Build all gems"
  task :all do
    GEMS.each do |gem_name|
      Rake::Task["build:#{gem_to_namespace(gem_name)}"].invoke
    end
  end
end

namespace :install do
  desc "Install all gems locally"
  task :all do
    GEMS.each do |gem_name|
      Rake::Task["install:#{gem_to_namespace(gem_name)}"].invoke
    end
  end
end

namespace :clean do
  desc "Clean all built files"
  task :all do
    GEMS.each do |gem_name|
      Rake::Task["clean:#{gem_to_namespace(gem_name)}"].invoke
    end
  end
end

namespace :rubocop do
  desc "Run RuboCop for all gems"
  task :all do
    GEMS.each do |gem_name|
      Rake::Task["rubocop:#{gem_to_namespace(gem_name)}"].invoke
    end
  end
end

namespace :release do
  desc "Generate release order JSON file"
  task :generate_order do
    require "json"

    puts "Generating release order..."

    # Start with pubid-core as it's the base dependency
    release_order = ["pubid-core"]

    # Add all other gems except the main pubid gem
    other_gems = GEMS.reject { |gem| ["pubid", "pubid-core"].include?(gem) }
    release_order.concat(other_gems.sort)

    # Add main pubid gem last (it depends on all others)
    release_order << "pubid"

    # Create the JSON structure
    release_config = {
      "release_order" => release_order,
    }

    # Write to file
    File.write("release-order.json", JSON.pretty_generate(release_config))
    puts "✓ Generated release-order.json with #{release_order.length} gems"
    puts "Release order: #{release_order.join(' -> ')}"
  end

  desc "Validate release order"
  task :validate_order do
    require "json"

    unless File.exist?("release-order.json")
      puts "✗ release-order.json not found. Run 'rake release:generate_order' first."
      exit 1
    end

    begin
      config = JSON.parse(File.read("release-order.json"))
      release_order = config["release_order"]

      puts "Validating release order..."

      # Check that all gems are included
      missing_gems = GEMS - release_order
      extra_gems = release_order - GEMS

      if missing_gems.any?
        puts "✗ Missing gems in release order: #{missing_gems.join(', ')}"
        exit 1
      end

      if extra_gems.any?
        puts "✗ Extra gems in release order: #{extra_gems.join(', ')}"
        exit 1
      end

      # Check that pubid-core comes before pubid
      core_index = release_order.index("pubid-core")
      pubid_index = release_order.index("pubid")

      if core_index.nil?
        puts "✗ pubid-core not found in release order"
        exit 1
      end

      if pubid_index.nil?
        puts "✗ pubid not found in release order"
        exit 1
      end

      if core_index >= pubid_index
        puts "✗ pubid-core must come before pubid in release order"
        exit 1
      end

      puts "✓ Release order is valid"
      puts "Release order: #{release_order.join(' -> ')}"
    rescue JSON::ParserError => e
      puts "✗ Invalid JSON in release-order.json: #{e.message}"
      exit 1
    end
  end

  desc "Show release order"
  task :show_order do
    require "json"

    unless File.exist?("release-order.json")
      puts "✗ release-order.json not found. Run 'rake release:generate_order' first."
      exit 1
    end

    begin
      config = JSON.parse(File.read("release-order.json"))
      release_order = config["release_order"]

      puts "Current release order:"
      release_order.each_with_index do |gem, index|
        puts "  #{index + 1}. #{gem}"
      end
    rescue JSON::ParserError => e
      puts "✗ Invalid JSON in release-order.json: #{e.message}"
      exit 1
    end
  end

  desc "Show release status for all gems"
  task :status do
    puts "Checking release status..."
    GEMS.each do |gem_name|
      in_gem_dir(gem_name) do
        puts "\n#{gem_name}:"

        # Check git status
        if system("git status --porcelain | grep -q .")
          puts "  ✗ Has uncommitted changes"
        else
          puts "  ✓ Clean working directory"
        end

        # Get current version from gemspec
        begin
          gemspec_file = Dir["*.gemspec"].first
          if gemspec_file
            spec = Gem::Specification.load(gemspec_file)
            current_version = spec.version.to_s
            puts "  📦 Current version: v#{current_version}"

            # Check if this version is already tagged
            version_tag = "v#{current_version}"
            if system("git tag -l #{version_tag} | grep -q #{version_tag}")
              puts "  ✓ Version #{current_version} is tagged"
            else
              puts "  ! Version #{current_version} not yet tagged"
            end

            # Check if there are any version tags for this gem
            gem_tags = `git tag -l | grep -E '^(#{gem_name}-)?v[0-9]' | sort -V`.strip.split("\n").reject(&:empty?)
            if gem_tags.any?
              latest_tag = gem_tags.last
              puts "  📋 Latest tag: #{latest_tag}"
            else
              puts "  ! No version tags found"
            end
          else
            puts "  ✗ No gemspec found"
          end
        rescue StandardError => e
          puts "  ✗ Error reading version: #{e.message}"
        end
      end
    end
  end
end

namespace :version do
  desc "Show current master version"
  task :show do
    require_relative "lib/pubid/version"
    puts "Master version: #{Pubid::VERSION}"
  end

  desc "Check if all gem versions and dependencies are synchronized with master version"
  task :check do
    require_relative "lib/pubid/version"
    master_version = Pubid::VERSION
    puts "Checking version synchronization..."
    puts "Master version: #{master_version}"

    all_synced = true

    # Check gem versions
    puts "\nChecking gem versions:"
    GEMS.each do |gem_name|
      in_gem_dir(gem_name) do
        gemspec_file = Dir["*.gemspec"].first
        if gemspec_file
          spec = Gem::Specification.load(gemspec_file)
          gem_version = spec.version.to_s
          if gem_version == master_version
            puts "  ✓ #{gem_name}: #{gem_version}"
          else
            puts "  ✗ #{gem_name}: #{gem_version} (expected #{master_version})"
            all_synced = false
          end
        else
          puts "  ✗ #{gem_name}: No gemspec found"
          all_synced = false
        end
      rescue StandardError => e
        puts "  ✗ #{gem_name}: Error reading version: #{e.message}"
        all_synced = false
      end
    end

    # Check dependencies
    puts "\nChecking pubid-* dependencies:"
    GEMS.each do |gem_name|
      gemspec_file = "gems/#{gem_name}/#{gem_name}.gemspec"

      if File.exist?(gemspec_file)
        content = File.read(gemspec_file)

        # Find all pubid-* dependencies
        pubid_deps = content.scan(/spec\.add_dependency "pubid-([^"]+)", "([^"]*)"/)

        if pubid_deps.any?
          gem_deps_synced = true
          pubid_deps.each do |dep_name, dep_version|
            dep_gem = "pubid-#{dep_name}"
            if GEMS.include?(dep_gem)
              if dep_version == "= #{master_version}"
                puts "  ✓ #{gem_name} -> #{dep_gem}: #{dep_version}"
              else
                puts "  ✗ #{gem_name} -> #{dep_gem}: #{dep_version} (expected = #{master_version})"
                gem_deps_synced = false
                all_synced = false
              end
            end
          end
        else
          puts "  - #{gem_name}: No pubid-* dependencies"
        end
      else
        puts "  ✗ #{gem_name}: Gemspec not found"
        all_synced = false
      end
    end

    if all_synced
      puts "\n✓ All gems and dependencies are synchronized with master version"
    else
      puts "\n✗ Some gems or dependencies are not synchronized"
      puts "Run 'rake version:sync' to fix synchronization issues"
      exit 1
    end
  end

  desc "Sync master version to all gem version files and dependencies"
  task :sync do
    require_relative "lib/pubid/version"
    master_version = Pubid::VERSION
    puts "Syncing master version #{master_version} to all gems..."

    # Update version files
    GEMS.each do |gem_name|
      # Handle special case for main pubid gem
      if gem_name == "pubid"
        version_file = "gems/pubid/lib/pubid/version.rb"
      else
        # Convert gem name to module path (pubid-core -> core, pubid-bsi -> bsi)
        module_name = gem_name.sub(/^pubid-/, "")
        version_file = "gems/#{gem_name}/lib/pubid/#{module_name}/version.rb"
      end

      if File.exist?(version_file)
        content = File.read(version_file)

        # Update the VERSION constant
        new_content = content.gsub(/VERSION = "[^"]*"\.freeze/,
                                   "VERSION = \"#{master_version}\".freeze")

        if content == new_content
          puts "  - #{gem_name} version already at #{master_version}"
        else
          File.write(version_file, new_content)
          puts "  ✓ Updated #{gem_name} version"
        end
      else
        puts "  ✗ Version file not found for #{gem_name}: #{version_file}"
      end
    end

    # Update gemspec dependencies
    puts "\nSyncing pubid-* dependencies in gemspecs..."
    GEMS.each do |gem_name|
      gemspec_file = "gems/#{gem_name}/#{gem_name}.gemspec"

      if File.exist?(gemspec_file)
        content = File.read(gemspec_file)
        original_content = content.dup

        # Update all pubid-* dependencies to use exact version
        content = content.gsub(/spec\.add_dependency "pubid-([^"]+)", "[^"]*"/) do |match|
          dep_gem = "pubid-#{$1}"
          # Only update if this dependency gem exists in our monorepo
          if GEMS.include?(dep_gem)
            "spec.add_dependency \"#{dep_gem}\", \"= #{master_version}\""
          else
            match # Keep original if not in our monorepo
          end
        end

        if content == original_content
          puts "  - #{gem_name} dependencies already synchronized"
        else
          File.write(gemspec_file, content)
          puts "  ✓ Updated #{gem_name} dependencies"
        end
      else
        puts "  ✗ Gemspec not found: #{gemspec_file}"
      end
    end

    puts "\nVersion sync complete!"
  end

  desc "Bump version and sync to all gems"
  task :bump, [:type] do |t, args|
    require_relative "lib/pubid/version"

    bump_type = args[:type] || "patch"
    unless %w[major minor patch].include?(bump_type)
      puts "Error: bump type must be major, minor, or patch"
      exit 1
    end

    current_version = Gem::Version.new(Pubid::VERSION)
    segments = current_version.segments

    case bump_type
    when "major"
      new_version = "#{segments[0] + 1}.0.0"
    when "minor"
      new_version = "#{segments[0]}.#{segments[1] + 1}.0"
    when "patch"
      new_version = "#{segments[0]}.#{segments[1]}.#{segments[2] + 1}"
    end

    puts "Bumping version from #{current_version} to #{new_version}"

    # Update master version file
    master_version_file = "lib/pubid/version.rb"
    content = File.read(master_version_file)
    new_content = content.gsub(/VERSION = "[^"]*"\.freeze/,
                               "VERSION = \"#{new_version}\".freeze")
    File.write(master_version_file, new_content)
    puts "  ✓ Updated master version"

    # Reload the version constant
    Object.send(:remove_const, :Pubid) if defined?(Pubid)
    load master_version_file

    # Sync to all gems
    Rake::Task["version:sync"].invoke
  end
end

# Default task
task default: ["test:all", "test:integration"]

# Convenience tasks
task test: "test:all"
task build: "build:all"
task install: "install:all"
task clean: "clean:all"
