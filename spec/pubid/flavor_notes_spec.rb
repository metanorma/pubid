# frozen_string_literal: true

require "spec_helper"

# The root CLAUDE.md keeps the cross-flavor contract only. Each flavor's own
# forensics live in docs/flavors/<flavor>.md, which never loads automatically —
# a session opens it from the index in the root file. This spec is the forcing
# function that keeps the index and the directory in step, in the same way that
# prefixes_spec.rb keeps the registry and the PREFIXES constants in step.
RSpec.describe "Flavor notes" do
  let(:repo_root) { File.expand_path("../..", __dir__) }
  let(:claude_md) { File.join(repo_root, "CLAUDE.md") }
  let(:flavors_dir) { File.join(repo_root, "docs", "flavors") }
  let(:claude_md_text) { File.read(claude_md) }

  # Every docs/flavors/<name>.md path the root file names.
  let(:indexed_names) do
    claude_md_text.scan(%r{docs/flavors/([a-z0-9_]+)\.md}).flatten.uniq.sort
  end

  let(:flavor_files) { Dir[File.join(flavors_dir, "*.md")].sort }

  let(:file_names) do
    flavor_files.map { |file| File.basename(file, ".md") }.sort
  end

  it "has a docs/flavors directory" do
    expect(Dir.exist?(flavors_dir)).to be(true)
  end

  it "names every flavor note file in the root CLAUDE.md index" do
    expect(file_names - indexed_names).to be_empty
  end

  it "names no flavor note file that does not exist" do
    expect(indexed_names - file_names).to be_empty
  end

  it "names each file after a directory under lib/pubid" do
    pattern = File.join(repo_root, "lib", "pubid", "*")
    dirs = Dir[pattern].select { |dir| File.directory?(dir) }
    expect(file_names - dirs.map { |dir| File.basename(dir) }).to be_empty
  end

  it "writes a non-empty note for every flavor" do
    too_small = flavor_files.select { |file| File.size(file) < 200 }
    expect(too_small).to be_empty
  end

  it "keeps the root CLAUDE.md small enough to load in every session" do
    # The split exists to bound this file. 100 KB leaves room to grow while
    # still catching a flavor bullet appended to the root file by mistake.
    expect(File.size(claude_md)).to be < 100_000
  end
end
