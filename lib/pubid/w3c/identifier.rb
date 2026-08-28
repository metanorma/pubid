# frozen_string_literal: true

module Pubid
  module W3c
    # Base class for every W3C identifier AND the flavor's parse/create entry
    # point. Concrete identifiers under Pubid::W3c::Identifiers descend from
    # this class (one per W3C maturity level), so a parsed W3C id is an
    # instance of Pubid::W3c::Identifier.
    #
    # W3C identifiers are flat: a slug `number`, an optional publication `date`
    # (kept verbatim as a string — width varies: 8-digit YYYYMMDD, or legacy
    # 6-digit YYMMDD / 4-digit MMDD), and a document-type carried by the
    # concrete class (its `type_prefix` returns the printed token, e.g. "WD").
    class Identifier < ::Pubid::Identifier
      # Document slug, e.g. "charmod", "css-backgrounds-3", "07-WebData".
      #
      # This is the relaton index key: Relaton::Index sorts and bsearches every
      # row on `id.root.number.to_s`, and an empty key degrades that binary
      # search to a linear scan over the whole index — silently, with no error.
      # Every W3C identifier is its own root (the flavor has no supplement or
      # wrapper type), so this attribute is always the key and must never be
      # empty. It was named `code` before; there is no alias.
      #
      # It redefines the parent ::Pubid::Identifier's
      # `attribute :number, Components::Code` as a plain :string. CLAUDE.md
      # records that doing so on a class the concrete types INHERIT from can
      # resolve against the parent definition nondeterministically under
      # multi-flavor load (the IEEE lesson). That hazard does not apply to W3C's
      # shape, and the reason is worth keeping: lutaml's `inherited` hook
      # deep-dups the parent's attribute table into each subclass at
      # class-definition time (serialize/initialization.rb#initialize_attrs), so
      # a subclass holds a SNAPSHOT, not a live view. A base-level override is
      # therefore safe iff every subclass body opens after this body has run —
      # and Ruby resolves the superclass constant, running this file to
      # completion, before opening any leaf body. That holds because this class
      # lives in ONE file, in ONE class body, and is never reopened. Split it
      # the way IEEE splits its base and a leaf can snapshot a half-built
      # parent, silently reverting `number` to Components::Code. The `date`
      # override below has relied on the same property since the flavor landed.
      # spec/pubid/w3c/root_number_spec.rb pins it, and is only meaningful under
      # the FULL suite.
      attribute :number, :string
      # Publication date verbatim, or nil. Overrides the base Components::Date
      # attribute with a plain string (same mechanism JIS uses for `number`):
      # W3C dates are opaque digit runs that must round-trip exactly, and are
      # never re-parsed as calendar dates.
      attribute :date, :string

      # Polymorphic type map for lutaml::Model key_value (de)serialization: maps
      # each subclass's polymorphic_name to its class name so a stored hash
      # rebuilds the correct identifier type via from_hash.
      W3C_TYPE_MAP = {
        "pubid:w3c:standard" => "Pubid::W3c::Identifiers::Standard",
        "pubid:w3c:note" => "Pubid::W3c::Identifiers::Note",
        "pubid:w3c:draft-note" => "Pubid::W3c::Identifiers::DraftNote",
        "pubid:w3c:working-draft" => "Pubid::W3c::Identifiers::WorkingDraft",
        "pubid:w3c:candidate-recommendation" =>
          "Pubid::W3c::Identifiers::CandidateRecommendation",
        "pubid:w3c:candidate-recommendation-draft" =>
          "Pubid::W3c::Identifiers::CandidateRecommendationDraft",
        "pubid:w3c:recommendation" =>
          "Pubid::W3c::Identifiers::Recommendation",
        "pubid:w3c:proposed-recommendation" =>
          "Pubid::W3c::Identifiers::ProposedRecommendation",
        "pubid:w3c:proposed-edited-recommendation" =>
          "Pubid::W3c::Identifiers::ProposedEditedRecommendation",
        "pubid:w3c:superseded-recommendation" =>
          "Pubid::W3c::Identifiers::SupersededRecommendation",
        "pubid:w3c:obsolete-recommendation" =>
          "Pubid::W3c::Identifiers::ObsoleteRecommendation",
      }.freeze

      key_value do
        map "_type", to: :_type, polymorphic_map: W3C_TYPE_MAP
        map "number", to: :number
        map "date", to: :date
      end

      # Publisher is always "W3C". A plain constant (not a `publisher` method)
      # so it doesn't shadow the inherited lutaml `publisher` attribute, which
      # would otherwise fail serialization type validation.
      PUBLISHER = "W3C"

      # The printed document-type token (e.g. "WD"). nil for the bare-slug
      # Standard form; concrete typed subclasses override it.
      def type_prefix
        nil
      end

      attr_reader :with_publisher

      # Publication year derived from an 8-digit YYYYMMDD date, else nil. `date`
      # is a plain string here (not a Components::Date), so the inherited
      # `year` — which calls `date&.year` — would break; override it.
      def year
        return nil unless date.is_a?(::String) && date.length == 8

        date[0, 4]
      end

      def to_s(with_publisher: true, **opts)
        @with_publisher = with_publisher
        render(format: :human, **opts)
      end

      # from_hash is the shared polymorphic dispatch on Pubid::Identifier;
      # W3C_TYPE_MAP remains as the key_value polymorphic_map.

      # Parse a W3C identifier string into an identifier object
      # @param identifier [String] The W3C identifier string to parse
      # @return [Identifier] The appropriate identifier object
      # @raise [RuntimeError] If parsing fails
      def self.parse(identifier)
        # Reject pathological inputs before they reach the parser
        # (CodeQL rb/polynomial-redos barrier — inline .length by design).
        if identifier.length > Pubid::MAX_INPUT_LENGTH
          raise ArgumentError, Pubid::INPUT_TOO_LONG_MESSAGE
        end

        parsed = Parser.parse(identifier)
        Builder.build(parsed)
      rescue Parslet::ParseFailed => e
        raise "Failed to parse W3C identifier '#{identifier}': #{e.message}"
      end
    end
  end
end
