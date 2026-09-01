# frozen_string_literal: true

module Pubid
  module Etsi
    # Base class for all ETSI identifiers. Canonical name Pubid::Etsi::Identifier;
    # every concrete ETSI identifier descends from it.
    class Identifier < ::Pubid::Identifier
      # Let Parslet::ParseFailed propagate on a bad reference (matching ISO), so
      # relaton-cli's `rescue Parslet::ParseFailed` fetch handler catches it
      # instead of a bare RuntimeError.
      def self.parse(identifier)
        parsed = Parser.parse(identifier)
        Builder.build(parsed)
      end

      attribute :type, :string
      attribute :version, Pubid::Etsi::Components::Version
      attribute :date, Pubid::Components::Date
      # Stored as a plain string (always "ETSI") so it round-trips through
      # to_hash/from_hash. Was previously a `def publisher` method, which made
      # lutaml serialize a String against the Components::Publisher attribute and
      # raise on to_hash.
      attribute :publisher, :string, default: -> { "ETSI" }

      def ==(other)
        return false unless other.is_a?(Pubid::Etsi::Identifier)

        type == other.type &&
          code == other.code &&
          version == other.version &&
          date == other.date
      end

      # The document code is composed from the split index columns declared on
      # EtsiStandard (`number`/`minor`/`parts`). Returning nil here keeps `==`
      # and the URN generator total for the abstract base and for a supplement
      # whose own base is missing; EtsiStandard composes the real value and
      # SupplementIdentifier delegates to its base.
      def code
        nil
      end

      # `parts` is a plain collection attribute on the leaf, so the base
      # #exclude reaches it directly and nils it. It must come back as an EMPTY
      # ARRAY instead: a part-less reference parses with `parts` defaulting to
      # [], so a nil here would make `==` — and therefore #matches? — fail
      # against exactly the reference this exclusion exists to match. Same
      # "reset the whole cluster" rule recorded for CSA's year and IEEE's
      # year/month/day in CLAUDE.md.
      #
      # This also covers supplements: the base #exclude recurses into the
      # nested `base` identifier through exclude_from_nested, which re-enters
      # this method on the inner EtsiStandard.
      def exclude(*args)
        result = super
        part_keys = args & %i[part parts]
        if !part_keys.empty? && result.respond_to?(:parts=)
          result.parts = []
        end
        result
      end
    end

  end
end
