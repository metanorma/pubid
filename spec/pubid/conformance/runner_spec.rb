# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

# The conformance gate may never pass vacuously: an absent or empty
# corpus (wrong checkout ref, missing testsuite) once produced
# "TOTAL failures: 0" over zero flavors - a green no-op.
RSpec.describe Pubid::Conformance::Runner do
  describe "#run over a passing flavor" do
    it "reports no failures, as Strings not identifiers" do
      repo = ENV.fetch("PUBID_TESTSUITE_PATH",
                       File.expand_path("../../../../pubid-testsuite", __dir__))
      skip "pubid-testsuite corpus absent" unless File.directory?(File.join(
                                                                    repo, "tests", "amca"
                                                                  ))

      failures = described_class.new.run(["amca"])
      expect(failures).to be_empty
    end
  end

  describe "#run with an empty corpus" do
    it "refuses to report vacuous success" do
      Dir.mktmpdir do |tmp|
        corpus = File.join(tmp, "tests")
        FileUtils.mkdir_p(corpus)
        runner = described_class.new
        allow(ENV).to receive(:fetch).with("PUBID_TESTSUITE_PATH", anything)
          .and_return(tmp)
        expect { runner.run }
          .to raise_error(ArgumentError, /no corpus flavors found/)
      end
    end
  end
end
