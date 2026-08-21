# frozen_string_literal: true

require "spec_helper"

# Regression guard for CodeQL rb/polynomial-redos.
#
# Several flavors normalize identifier strings with regexes that CodeQL flags as
# polynomial-time on adversarial input. Ruby 3.2+ already memoizes those regexes
# to linear time, so they are not a live exploit on supported Rubies; rewriting
# them with possessive/atomic quantifiers is actively harmful because it DISABLES
# that memoization and reintroduces the O(n^2) blow-up. Instead, every public
# `parse` entry point bounds the input length (Pubid::MAX_INPUT_LENGTH) before it
# can reach those regexes — the mitigation CodeQL itself recommends.
#
# These specs pin that contract:
#   1. real identifiers keep parsing unchanged,
#   2. over-length input is rejected with ArgumentError,
#   3. even the longest *accepted* pathological input parses well within budget.
RSpec.describe "ReDoS input-length guard" do
  # Public parse entry points for the flavors whose regexes were flagged, plus
  # the top-level dispatcher. Each is a distinct barrier location.
  ENTRY_POINTS = {
    "Pubid.parse" => ->(s) { Pubid.parse(s) },
    "Pubid::Nist.parse" => ->(s) { Pubid::Nist.parse(s) },
    "Pubid::Bsi.parse" => ->(s) { Pubid::Bsi.parse(s) },
    "Pubid::Ieee.parse" => ->(s) { Pubid::Ieee.parse(s) },
    "Pubid::Csa.parse" => ->(s) { Pubid::Csa.parse(s) },
    "Pubid::Ashrae.parse" => ->(s) { Pubid::Ashrae.parse(s) },
    "Pubid::CenCenelec.parse" => ->(s) { Pubid::CenCenelec.parse(s) },
    "Pubid::Cie.parse" => ->(s) { Pubid::Cie.parse(s) },
    "Pubid::Iso.parse" => ->(s) { Pubid::Iso.parse(s) },
    "Pubid::Iec.parse" => ->(s) { Pubid::Iec.parse(s) },
    "Pubid::Idf.parse" => ->(s) { Pubid::Idf.parse(s) },
    "Pubid::Ietf.parse" => ->(s) { Pubid::Ietf.parse(s) },
    "Pubid::Iana.parse" => ->(s) { Pubid::Iana.parse(s) },
    # Class-level funnels that direct callers (and CodeQL sources) can hit
    # without passing through the module-level method above.
    "Pubid::Bsi::Identifier.parse" => ->(s) { Pubid::Bsi::Identifier.parse(s) },
    "Pubid::Csa::Identifier.parse" => ->(s) { Pubid::Csa::Identifier.parse(s) },
    "Pubid::Iso::Identifier.parse" => ->(s) { Pubid::Iso::Identifier.parse(s) },
    "Pubid::Iec::Identifier.parse" => ->(s) { Pubid::Iec::Identifier.parse(s) },
    # relaton reaches this one directly via `pubid_class:`.
    "Pubid::Ietf::Identifier.parse" =>
      ->(s) { Pubid::Ietf::Identifier.parse(s) },
    "Pubid::Iana::Identifier.parse" =>
      ->(s) { Pubid::Iana::Identifier.parse(s) },
  }.freeze

  it "exposes a sane, documented maximum input length" do
    expect(Pubid::MAX_INPUT_LENGTH).to be_a(Integer)
    expect(Pubid::MAX_INPUT_LENGTH).to eq(1000)
  end

  describe "rejects over-length input with ArgumentError" do
    let(:over_length) { "A" * (Pubid::MAX_INPUT_LENGTH + 1) }

    ENTRY_POINTS.each do |name, parser|
      it "#{name} raises ArgumentError" do
        expect { parser.call(over_length) }
          .to raise_error(ArgumentError, /maximum length/)
      end
    end
  end

  describe "accepts input at the boundary without a length error" do
    let(:at_limit) { "A" * Pubid::MAX_INPUT_LENGTH }

    ENTRY_POINTS.each do |name, parser|
      it "#{name} does not raise ArgumentError for a #{Pubid::MAX_INPUT_LENGTH}-char input" do
        # It may still be an unparseable identifier (any StandardError is fine);
        # it must simply not be rejected by the length guard.
        parser.call(at_limit)
      rescue ArgumentError => e
        raise if e.message.include?("maximum length")
      rescue StandardError
        # Unparseable content is acceptable — we only assert the guard didn't fire.
      end
    end
  end

  describe "the longest ACCEPTED input stays fast (memoized regexes are linear)" do
    # These inputs are exactly MAX_INPUT_LENGTH characters — the worst case the
    # guard lets through — and are packed with the exact repeat characters
    # CodeQL warned about, so they run through the previously-flagged regexes.
    # On Ruby 3.2+ the memoized regexes handle this in linear time; if a future
    # change reintroduced backtracking (e.g. by adding possessive/atomic groups),
    # these would blow past the budget. That is the real regression this catches.
    budget = 2.0 # seconds — generous to avoid CI flakiness

    # Fill exactly to the limit so the guard accepts the input.
    fill = ->(prefix, char) { prefix + (char * (Pubid::MAX_INPUT_LENGTH - prefix.length)) }
    cases = {
      "Pubid::Nist.parse zero-pump" => ["Pubid::Nist", fill.call("NIST SP 800-", "0")],
      "Pubid::Nist.parse space-pump" => ["Pubid::Nist", fill.call("NIST SP ", " ")],
      "Pubid::Ieee.parse zero-pump" => ["Pubid::Ieee", fill.call("IEEE Std ", "0")],
      "Pubid::Csa.parse space-pump" => ["Pubid::Csa", "CSA B1:23" + (" " * (Pubid::MAX_INPUT_LENGTH - 18)) + "PACKAGE"],
      "Pubid::Bsi.parse space-pump" => ["Pubid::Bsi", fill.call("BS 1 ", " ")],
    }

    cases.each do |name, (mod_name, input)|
      it "#{name} (#{Pubid::MAX_INPUT_LENGTH} chars) finishes within #{budget}s" do
        expect(input.length).to be <= Pubid::MAX_INPUT_LENGTH # sanity: accepted, not rejected
        mod = Object.const_get(mod_name)
        elapsed = clock { mod.parse(input) }
        expect(elapsed).to be < budget
      end
    end

    def clock
      start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      begin
        yield
      rescue StandardError
        # Unparseable pathological content is fine — we are timing cost, not result.
      end
      Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
    end
  end

  describe "still parses representative real identifiers unchanged" do
    {
      "Pubid::Nist" => "NIST SP 800-38A",
      "Pubid::Ieee" => "IEEE Std 1076-2004",
      "Pubid::Csa" => "CSA B108:23 PACKAGE",
      "Pubid::Iso" => "ISO 216",
    }.each do |mod_name, identifier|
      it "#{mod_name}.parse(#{identifier.inspect}) round-trips" do
        mod = Object.const_get(mod_name)
        expect(mod.parse(identifier).to_s).to eq(identifier)
      end
    end
  end
end
