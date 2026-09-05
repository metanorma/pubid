# frozen_string_literal: true

require "spec_helper"

# The MR string is ECMA's third identity surface, and `to_slug` derives an
# output FILENAME from it — so two distinct documents sharing a slug means one
# overwrites the other.
#
# Before the edition/volume work ECMA defined no `mr_*` hooks at all:
#   * `mr_publisher` was nil (ECMA keeps its publisher in the PUBLISHER
#     constant, not the inherited `publisher` attribute),
#   * `mr_type` was nil (the Builder picks a class, it never sets a
#     `typed_stage`), so `ECMA-101` and `ECMA TR/101` both slugged to "101",
#   * and the base `mr_edition` (`edition&.number`) RAISED NoMethodError on
#     ECMA's plain-string edition — for all 740 edition-carrying corpus rows.
module EcmaMrStringSpec
  PASS_FILES = Dir.glob(
    File.join(__dir__, "../../fixtures/ecma/identifiers/pass", "*.txt"),
  ).freeze
end

RSpec.describe "Pubid::Ecma MR string" do
  # `pass/` may carry `!input!rendered` marker lines for a normalizing parse,
  # so read through the shared helper rather than a bespoke line filter — a
  # raw read would feed the marker to the parser verbatim.
  include FixtureFileHelper

  {
    "ECMA-101" => "ecma.101",
    "ECMA TR/101" => "ecma.tr.101",
    "ECMA MEM/1970" => "ecma.mem.1970",
    "ECMA-418-1" => "ecma.418-1",
    "ECMA-269 ed3" => "ecma.269.ed3",
    "ECMA-402 ed5.1" => "ecma.402.ed5-1",
    "ECMA-269 ed3 vol2" => "ecma.269.ed3.vol2",
    "ECMA TR/18 ed2" => "ecma.tr.18.ed2",
  }.each do |input, mr|
    it "renders #{input.inspect} as #{mr.inspect}" do
      expect(Pubid::Ecma::Identifier.parse(input).to_mr_string).to eq(mr)
    end
  end

  it "does not collide a standard with a technical report of the same number" do
    standard = Pubid::Ecma::Identifier.parse("ECMA-101").to_mr_string
    report = Pubid::Ecma::Identifier.parse("ECMA TR/101").to_mr_string
    expect(standard).not_to eq(report)
  end

  it "does not raise on an edition-carrying identifier" do
    id = Pubid::Ecma::Identifiers::Standard.new(number: "269", edition: "3")
    expect { id.to_mr_string }.not_to raise_error
  end

  # The MR joins SEGMENTS with ".", so a dot inside one would break the
  # documented segment structure. The MR is free to be lossy here because
  # nothing parses an ECMA MR back (`Parsers::MrString::FLAVOR_MAP` has no ECMA
  # entry); the URN, which UrnParser inverts, keeps the dot instead.
  it "collapses the dot of a decimal edition" do
    expect(Pubid::Ecma::Identifier.parse("ECMA-402 ed5.1").to_mr_string)
      .to eq("ecma.402.ed5-1")
  end

  it "derives the slug straight from the MR string" do
    id = Pubid::Ecma::Identifier.parse("ECMA-269 ed3 vol2")
    expect(id.to_slug).to eq(id.to_mr_string)
  end

  describe "every pass fixture" do
    # Tripwire: a wrong glob would make the sweep below vacuous.
    it "finds the ECMA pass fixtures" do
      expect(EcmaMrStringSpec::PASS_FILES).not_to be_empty
    end

    it "yields a non-empty, filename-safe slug" do
      inputs = EcmaMrStringSpec::PASS_FILES.flat_map do |file|
        read_pass_fixture_entries(file).map(&:first)
      end

      bad = inputs.filter_map do |reference|
        slug = Pubid::Ecma::Identifier.parse(reference).to_slug
        "#{reference} => #{slug.inspect}" unless slug.match?(/\A[a-z0-9._-]+\z/)
      end

      expect(bad).to be_empty
    end
  end
end
