# frozen_string_literal: true

require "parslet"

module Pubid
  module Ecma
    # Parslet grammar for ECMA identifiers.
    #
    # Four printed forms:
    #   ECMA-411          standard
    #   ECMA-418-1        standard with part
    #   ECMA TR/101       technical report
    #   ECMA MEM/1970     memento
    #
    # Any of them may carry an edition and a volume, in that order:
    #   ECMA-269 ed3      third edition
    #   ECMA-402 ed5.1    decimal edition (real: ECMA-402)
    #   ECMA-269 ed3 vol2 second volume of the third edition
    #
    # Each branch captures its number under a distinct key so the builder can
    # pick the identifier class without a separate type token. Numbers are kept
    # as strings to preserve any leading zeros.
    class Parser < Parslet::Parser
      rule(:digits) { match["0-9"].repeat(1) }

      rule(:prefix) { str("ECMA") }

      rule(:tr) { str(" TR/") >> digits.as(:tr_number) }

      rule(:mem) { str(" MEM/") >> digits.as(:mem_number) }

      # Standards print with a hyphen ("ECMA-6"), but references are commonly
      # written with a space ("ECMA 6"). Both parse; the renderer normalises to
      # the hyphen, so the space form round-trips as "ECMA-6" by design and must
      # never enter the byte-exact `pass` fixtures.
      rule(:standard_separator) { str("-") | str(" ") }

      rule(:standard) do
        standard_separator >> digits.as(:number) >>
          (str("-") >> digits.as(:part)).maybe
      end

      # Editions are not all integers: ECMA-402 ed5.1 is a real document. The
      # value is stored verbatim so it renders and serializes unchanged.
      rule(:edition_number) { digits >> (str(".") >> digits).repeat(0) }

      rule(:edition) { str(" ed") >> edition_number.as(:edition) }

      rule(:volume) { str(" vol") >> digits.as(:volume) }

      # The suffixes attach AFTER the type alternation, so a technical report
      # and a memento carry them exactly as a standard does.
      #
      # Two PEG facts this arrangement depends on:
      #
      # 1. `standard` cannot shadow " TR/" or " MEM/", because after the space
      #    it demands a digit and "T"/"M" are not digits. Keeping tr|mem first
      #    is belt-and-braces; the DISJOINT FIRST CHARACTER is the load-bearing
      #    invariant.
      # 2. Appending a sequence moves the alternation out of tail position, so
      #    Parslet no longer threads consume_all into it and will not backtrack
      #    into an alternative that already succeeded. A future branch that
      #    could match a proper prefix of another branch's input would now fail
      #    the whole parse instead of being rescued by the next alternative.
      rule(:identifier) do
        prefix >> (tr | mem | standard) >> edition.maybe >> volume.maybe
      end

      rule(:root) { identifier }

      def self.parse(input)
        new.parse(input)
      end
    end
  end
end
