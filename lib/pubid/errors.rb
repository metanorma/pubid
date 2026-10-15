# frozen_string_literal: true

# no `require "pubid"` here: errors.rb loads from pubid.rb itself, and
# the umbrella self-require is a circular load whose failure order is
# platform-dependent (windows raises mid-cycle where linux tolerates it)
require "parslet"

module Pubid
  # Every failure pubid raises.
  #
  # The three classes below have three different superclasses, chosen so that
  # code written against the old contract keeps working: relaton-cli rescues
  # `Parslet::ParseFailed`, and the input guards have always raised
  # `ArgumentError`. What unifies them is the marker module
  # {Pubid::Errors::Error}, which every one of them includes, so a caller that
  # wants "pubid could not do this" writes one rescue:
  #
  #   begin
  #     Pubid::Iso.parse(reference)
  #   rescue Pubid::Errors::Error => e
  #     warn e.message
  #   end
  #
  # A URN failure deliberately does not inherit `Parslet::ParseFailed`: no
  # grammar runs, so there is no parse failure to report.
  module Errors
    # Marker module included by every pubid error. Rescue this to catch all
    # of them, whatever their superclass.
    module Error; end

    # A printed identifier could not be turned into an identifier object.
    #
    # Raised for a grammar rejection, and also for the few flavors that reject
    # an input before the grammar runs (a CSA comment line, a bad ISBN check
    # digit). Those synthetic failures carry no parslet cause, so
    # {#parse_failure_cause} is nillable — check it before calling
    # `ascii_tree` on it.
    #
    # v1's `Pubid::Core::Errors::ParseError` flattened the cause into the
    # message and threw the object away. This one keeps it.
    class ParseError < ::Parslet::ParseFailed
      include Error

      # The string that could not be parsed, when it is known.
      # @return [String, nil]
      attr_reader :input

      # The flavor whose grammar rejected the input, lowercased ("iso").
      #
      # This is the flavor that actually ran, which is not always the one the
      # caller named: `Pubid::Iso.parse("ITU-T G.711")` routes through the
      # MR-string parser into ITU, and reports "itu".
      # @return [String, nil]
      attr_reader :flavor

      # @param message [String]
      # @param parse_failure_cause [Parslet::Cause, nil] parslet's structured
      #   cause, nil for a failure raised without running a grammar
      # @param input [String, nil]
      # @param flavor [String, nil]
      def initialize(message, parse_failure_cause = nil, input: nil,
                     flavor: nil)
        super(message, parse_failure_cause)
        @input = input
        @flavor = flavor
      end
    end

    # A URN could not be turned into an identifier object.
    class UrnParseError < ::StandardError
      include Error
    end

    # The input was not a String, or was longer than {Pubid::MAX_INPUT_LENGTH}.
    #
    # Inherits `ArgumentError` because that is what the guards have always
    # raised, and because the input is wrong in kind rather than unparseable.
    class InvalidInputError < ::ArgumentError
      include Error
    end
  end
end
