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
      in_gem_dir(gem_name) { sh "bundle exec rspec" }
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

# Default task
task default: ["test:all", "test:integration"]

# Convenience tasks
task test: "test:all"
task build: "build:all"
task install: "install:all"
task clean: "clean:all"
