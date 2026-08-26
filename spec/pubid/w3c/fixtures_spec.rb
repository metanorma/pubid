# frozen_string_literal: true

require "spec_helper"

# Bulk round-trip over hand-picked real identifiers from relaton-data-w3c.
# Every line must satisfy parse(x).to_s == x (100% — no pass-rate slack, since
# these are curated to cover all three printed shapes plus the digit-ending-slug
# and legacy-date stressors).
RSpec.describe "Pubid::W3c fixtures round-trip" do
  fixture_glob = File.join(__dir__, "../../fixtures/w3c/identifiers/pass/*.txt")

  Dir.glob(fixture_glob).each do |file|
    describe File.basename(file) do
      lines = File.readlines(file).map(&:strip)
        .reject { |l| l.empty? || l.start_with?("#") }

      lines.each do |pubid|
        it "round-trips #{pubid.inspect}" do
          expect(Pubid::W3c.parse(pubid).to_s).to eq(pubid)
        end
      end
    end
  end
end
