# frozen_string_literal: true

# Usage:
#
# Create main branch with all repositories that have main branch.
# Make dir for mono-repo, initialize git, use main branch, add this file, and commit:
#   mkdir monorepo
#   cp monorepo_importer.rb monorepo
#   cd monorepo
#   git init
#   git checkout -b main
#   git add .
#   git commit -m "Initial commit"
# Then run this script to import main branches of all repositories:
#   ruby monorepo_importer.rb
# To update the mono-repo with latest changes from all repositories commit all changes and run this script:
#   ruby monorepo_importer.rb
#
# Create additional branches for each repository that has branch with the same name.
# Make an empty branch:
#   git checkout --orphan <branch_name>
#   git rm -rf pubid-*
#   git add .
#   git commit -m "Initial commit"
# Then run this script to import branches with the same name from all repositories:
#   ruby monorepo_importer.rb
#
# To add a new repository to the current branch in the mono-repo use git commands:
#   git remote add remote-<repo_name> <repo_url> <branch_name>
#   git fetch remote-<repo_name>
#   git subtree add --prefix=<repo_name> remote-<repo_name>/<branch_name>
# Add the new repository to the list of repositories in this script if it isn't already there.

require 'fileutils'

branch = `git rev-parse --abbrev-ref HEAD`.strip || "main"

# Configuration
gems = %w[pubid-bsi pubid-ccsds pubid-cen pubid-core pubid-etsi pubid-iec
          pubid-ieee pubid-iso pubid-itu pubid-jis pubid-nist pubid-plateau]

gems.each do |folder_name|
  repo_url = "git@github.com:metanorma/#{folder_name}.git"
  remote_name = "remote-#{folder_name}"

  # Add remote if it doesn't exist
  existing_remotes = `git remote`.split("\n")
  unless existing_remotes.include?(remote_name)
    puts "Adding remote #{remote_name} for #{repo_url}..."
    system("git remote add #{remote_name} #{repo_url}")
  end

  # Fetch remote
  puts "Fetching remote #{remote_name}..."
  system("git fetch #{remote_name}")

  # Check if branch exists in remote
  remote_branches = `git ls-remote --heads #{remote_name} #{branch}`
  if remote_branches.empty?
    puts "⚠️  Branch '#{branch}' not found in #{folder_name}, skipping."
    next
  end

  if Dir.exist?(folder_name)
    # If folder exists, pull latest changes into it
    puts "Pulling latest changes into #{folder_name}..."
    msg = "'Pulled subtree for #{folder_name} (branch #{branch})'"
    result = system("git subtree pull --prefix=#{folder_name} #{remote_name} #{branch} -m #{msg}") # --squash")
    unless result
      puts "⚠️ Conflict detected. Overwriting with remote branch '#{branch}' of #{folder_name}..."

      unless system("git checkout --theirs #{folder_name}/")
        puts "⚠️ Failed to checkout theirs for #{folder_name}."
        puts "Please resolve conflicts manually."
        exit 1
      end
      system("git add #{folder_name}/")
      system("git commit -m #{msg}")
    end
  else
    # If folder does not exist, add the subtree
    puts "Adding new repository into #{folder_name}..."
    system("git subtree add --prefix=#{folder_name} #{remote_name}/#{branch}") # --squash")
  end
end

puts "✅ All repositories processed on branch '#{branch}' with conflict fallback."
