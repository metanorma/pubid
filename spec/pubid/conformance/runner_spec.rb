# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

# The conformance gate may never pass vacuously: an absent or empty
# corpus (wrong checkout ref, missing testsuite) once produced
# "TOTAL failures: 0" over zero flavors - a green no-op.
RSpec.describe Pubid::Conformance::Runner do
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
