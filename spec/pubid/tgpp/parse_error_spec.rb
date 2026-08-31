# frozen_string_literal: true

require "spec_helper"

RSpec.describe "3GPP parse error class" do
  # An unrecognized reference must raise Parslet::ParseFailed (matching ISO and
  # ETSI, and what relaton-cli's fetch handler rescues) rather than a bare
  # RuntimeError, which escapes relaton-cli as a raw Ruby backtrace.
  [
    "3GPP 1234",  # publisher token, but no type token
    "TS",         # type token, but no number core
    "TS foo",     # type token, but the number core is not dotted digits
    "",           # empty input
  ].each do |bad|
    context "with the unrecognized reference #{bad.inspect}" do
      it "raises Parslet::ParseFailed from Identifier.parse" do
        expect { Pubid::Tgpp::Identifier.parse(bad) }
          .to raise_error(Parslet::ParseFailed)
      end

      it "raises Parslet::ParseFailed from the module-level parse" do
        expect { Pubid::Tgpp.parse(bad) }.to raise_error(Parslet::ParseFailed)
      end
    end
  end

  it "still parses a valid bare reference" do
    expect(Pubid::Tgpp::Identifier.parse("3GPP TS 23.207").to_s)
      .to eq("TS 23.207")
  end

  it "still parses a valid full reference" do
    expect(Pubid::Tgpp::Identifier.parse("TS 29.198-04-1:REL-5/5.0.0").to_s)
      .to eq("TS 29.198-04-1:REL-5/5.0.0")
  end

  # Over-long input is a different failure (input too long, not unparseable),
  # so it keeps its ArgumentError and never reaches the parser.
  it "still raises ArgumentError for over-long input" do
    expect { Pubid::Tgpp::Identifier.parse("TS #{'9' * 1001}") }
      .to raise_error(ArgumentError, /maximum length/)
  end
end
