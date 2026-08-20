# frozen_string_literal: true

require "parslet"

module Pubid
  module Ietf
    # Parslet grammar for the three IETF families. The top-level alternation is
    # keyed by leading token, and each alternative captures the raw fields the
    # Builder needs:
    #   * RFC        -> { number: }
    #   * sub-series -> { series:, number: }
    #   * draft      -> { draft_rest: }  (everything after "draft-"; the version
    #                    split is done in the Builder to keep the digit-tail
    #                    heuristic in one place)
    class Parser < Parslet::Parser
      rule(:space) { str(" ") }
      rule(:digit) { match["0-9"] }
      rule(:digits) { digit.repeat(1) }

      # "RFC 2119", and the zero-padded, space-less spelling the RFC editor's
      # rfc-index.xml emits ("RFC0001"). See #subseries for why.
      rule(:rfc) { str("RFC") >> space.maybe >> digits.as(:number) }

      # "BCP 3" / "STD 66" / "FYI 1".
      #
      # The space is optional and leading zeros are allowed because
      # rfc-index.xml writes the sub-series membership of an RFC in the padded,
      # space-less form -- <is-also><doc-id>STD0066</doc-id></is-also> -- and
      # relaton builds the STD/BCP/FYI <-> RFC cross-references from exactly
      # those elements without normalizing them itself. The Builder strips the
      # pad, so the printed form stays the canonical "STD 66".
      rule(:subseries) do
        (str("BCP") | str("STD") | str("FYI")).as(:series) >>
          space.maybe >> digits.as(:number)
      end

      # Internet-Draft slug characters: lowercase, digits and the "-", "+", "_"
      # separators, plus two historical shapes the published corpus carries --
      # a dot inside a topic token ("draft-ietf-pilc-2.5g3g-12") and uppercase
      # letters in protocol/organisation names ("draft-chapin-clnp-ISO8473-00").
      # 50 of the 166,740 relaton-data-ids identifiers need those two
      # characters; nothing else outside [a-z0-9-] occurs in the corpus.
      #
      # Widening the tail is unambiguous: the top-level alternation is keyed on
      # the leading token (RFC / BCP|STD|FYI / draft-), so a wider draft tail
      # cannot make another branch match.
      #
      # The whole remainder after "draft-" is captured; the Builder anchors the
      # optional trailing "-NN" version.
      rule(:draft_rest) { match['a-zA-Z0-9+_.\-'].repeat(1).as(:draft_rest) }
      rule(:draft) { str("draft-") >> draft_rest }

      rule(:identifier) { rfc | subseries | draft }
      rule(:root) { identifier }

      def self.parse(input)
        new.parse(input)
      end
    end
  end
end
