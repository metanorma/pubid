# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

RSpec.describe Pubid::Conformance::Pending do
  around do |example|
    # The implementation memoises the loaded registry at the class level.
    # Reset the cache on entry so each example loads against the tmpdir file.
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        @dir = dir
        Pubid::Conformance::Pending.instance_variable_set(:@registry, nil)
        example.run
        Pubid::Conformance::Pending.instance_variable_set(:@registry, nil)
      end
    end
  end

  def write_pending(contents)
    FileUtils.mkdir_p(File.join(@dir, "conformance"))
    File.write(File.join(@dir, "conformance", "pending.yaml"), contents)
  end

  before do
    # The gem hardcodes PATH = File.expand_path("../../../conformance/pending.yaml",
    # __dir__). To test against a tmpdir file we stub the const on every example;
    # stub_const is automatically reverted after each example.
    stub_const("#{described_class}::PATH",
               File.join(@dir, "conformance", "pending.yaml"))
  end

  describe ".for" do
    it "returns nil when no pending file exists" do
      expect(described_class.for("nist.handbook.0001")).to be_nil
    end

    it "returns the entry for an exact case-id match" do
      write_pending(<<~YAML)
        nist.handbook.0001:
          reason: HB compound prefix
          since: "2026-08-26"
          ref: TODO.correct-test-suite/08 PR-D1
      YAML
      entry = described_class.for("nist.handbook.0001")
      expect(entry["reason"]).to eq("HB compound prefix")
    end

    it "matches case-id globs (not just exact ids)" do
      write_pending(<<~YAML)
        "ieee.corrigendum.*":
          reason: status-draft routing
          since: "2026-08-26"
          ref: TODO.correct-test-suite/08 PR-F3
      YAML
      expect(described_class.for("ieee.corrigendum.6454")["ref"])
        .to include("PR-F3")
    end

    it "returns nil for case-ids outside the pending set" do
      write_pending(<<~YAML)
        bsi.bundled_identifier.0217:
          reason: nested polymorphic from_hash
          since: "2026-08-26"
          ref: TODO.correct-test-suite/08 PR-A
      YAML
      expect(described_class.for("ieee.handbook.0002")).to be_nil
    end

    it "returns nil for empty id (no match)" do
      write_pending(<<~YAML)
        bsi.foo.bar:
          reason: x
          since: "2026-08-26"
          ref: x
      YAML
      expect(described_class.for("")).to be_nil
    end
  end

  describe "entry validation (reject malformed at load)" do
    it "raises ArgumentError when an entry lacks reason" do
      write_pending(<<~YAML)
        bad.entry:
          since: "2026-08-26"
          ref: x
      YAML
      expect { described_class.for("bad.entry") }
        .to raise_error(ArgumentError, /needs reason and ref/)
    end

    it "raises ArgumentError when an entry lacks ref" do
      write_pending(<<~YAML)
        bad.entry:
          reason: r
          since: "2026-08-26"
      YAML
      expect { described_class.for("bad.entry") }
        .to raise_error(ArgumentError, /needs reason and ref/)
    end
  end

  describe "robustness" do
    it "returns {} for a comments-only file (no top-level mapping)" do
      write_pending("# only a comment\n")
      expect(described_class.for("anything")).to be_nil
    end
  end
end
