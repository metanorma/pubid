# frozen_string_literal: true

module Pubid
  module Oasis
    # Base class for every OASIS identifier AND the flavor's parse/create entry
    # point. The single concrete type `Identifiers::Standard` descends from this
    # class, so a parsed OASIS id is an instance of `Pubid::Oasis::Identifier`.
    #
    # OASIS identifiers are free-form slugs with an inconsistent internal
    # structure (spec name + version + approval stage + part + label, in
    # varying order). To guarantee a lossless round-trip we always keep the
    # exact printed slug verbatim in `original` (which alone drives `to_s`); the
    # remaining component fields are a best-effort decomposition for relaton
    # querying and can be nil without ever affecting the rendered string.
    class Identifier < ::Pubid::Identifier
      # The exact slug printed after "OASIS " — always set. Drives `to_s`, so
      # the printed form round-trips verbatim regardless of decomposition.
      attribute :original, :string
      # Best-effort decomposition (any may be nil). `number`/`label` are plain
      # slug fragments; `version`/`stage`/`part` carry the recognized fragment
      # verbatim (e.g. "3.0", "v1.2.1", "PS01", "Errata01", "Pt8", "Part1").
      #
      # `number` holds the specification name ("OSLC-CM", "STIX", "amqp-core").
      # It is the key relaton-index sorts and binary-searches on
      # (`id.root.number.to_s`), and it deliberately CLUSTERS: every version,
      # stage and part of one specification shares it, the same shape as an
      # IETF draft slug or an IANA registry slug.
      #
      # `number`/`stage`/`part` intentionally override the inherited
      # Components::Code / Components::Stage attributes with plain strings (the
      # mechanism JIS uses for `number` and W3C for `date`): OASIS names,
      # stages and parts are opaque tokens that must round-trip exactly and are
      # never re-parsed as structured parts. Redefining an inherited attribute
      # is only deterministic under multi-flavor load because this class body
      # lives in ONE file and is never reopened, so lutaml has finished
      # building the table before `Identifiers::Standard` snapshots it — DO NOT
      # split this class across two files.
      attribute :number, :string
      attribute :version, :string
      attribute :stage, :string
      attribute :part, :string
      attribute :label, :string

      # Polymorphic type map for lutaml::Model key_value (de)serialization: maps
      # the subclass's polymorphic_name to its class name so a stored hash
      # rebuilds the correct identifier type via from_hash.
      OASIS_TYPE_MAP = {
        "pubid:oasis:standard" => "Pubid::Oasis::Identifiers::Standard",
      }.freeze

      key_value do
        map "_type", to: :_type, polymorphic_map: OASIS_TYPE_MAP
        map "original", to: :original
        map "number", to: :number
        map "version", to: :version
        map "stage", to: :stage
        map "part", to: :part
        map "label", to: :label
      end

      # Publisher is always "OASIS". A plain constant (not a `publisher` method)
      # so it doesn't shadow the inherited lutaml `publisher` attribute, which
      # would otherwise fail serialization type validation.
      PUBLISHER = "OASIS"

      attr_reader :with_publisher

      def to_s(with_publisher: true, **opts)
        @with_publisher = with_publisher
        render(format: :human, **opts)
      end

      # The decomposition fields. Excluding any of them must also clear
      # `original`, which still spells the excluded value out verbatim.
      DECOMPOSITION_KEYS = %i[number version stage part label].freeze

      # Widen a partial reference. `#matches?` is
      # `exclude(*ignore) == other.exclude(*ignore)`, and `original` carries
      # every component verbatim, so without this a bare "OASIS WSDM" could
      # never match "OASIS WSDM-v1.1" however much the caller ignored.
      #
      # `original` is cleared ONLY when the exclusion touches the
      # decomposition — the "reset the whole cluster" rule CSA applies to its
      # year-format siblings. A plain `==` still compares `original`, so two
      # slugs that decompose alike but print differently stay distinct: the
      # decomposition loses fragment order and drops repeated fragments, so it
      # is not by itself an identity.
      def exclude(*args)
        result = super
        result.original = nil if args.intersect?(DECOMPOSITION_KEYS)
        result
      end

      # MR string hooks. `to_slug` delegates to `to_mr_string` and consumers
      # use it as an output FILENAME, so the slug must be unique per document.
      #
      # The publisher lives in the PUBLISHER constant rather than the inherited
      # lutaml attribute, so the base `mr_publisher` returns nil (the BIPM and
      # IANA case) and is supplied here.
      def mr_publisher
        PUBLISHER.downcase
      end

      # The whole verbatim slug, not the decomposed fields: decomposition loses
      # fragment order and drops repeated fragments, so "x-1.0-os-Pt1" and
      # "x-1.0-Pt1-os" would assemble to one slug. `original` cannot collide.
      def mr_number_with_part
        mr_sanitize(original)
      end

      # from_hash is the shared polymorphic dispatch on Pubid::Identifier;
      # OASIS_TYPE_MAP remains as the key_value polymorphic_map.

      # Parse an OASIS identifier string into an identifier object
      # @param identifier [String] The OASIS identifier string to parse
      # @return [Identifier] The Standard identifier object
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
        raise "Failed to parse OASIS identifier '#{identifier}': #{e.message}"
      end

      private

      # Filter by CHARSET, not by an enumerated escape list, so a field added
      # later cannot leak an unsafe character (the BIPM `mr_slug` precedent).
      # Three characters need it today: the "." in every version —
      # Renderers::MrString joins SEGMENTS with ".", so a dot inside one breaks
      # the documented segment structure — plus the space and "]" of a few
      # malformed records.
      #
      # A RUN of non-alphanumerics collapses to one "-", which is why "-" is
      # outside the kept set (BIPM's form, not ETSI's): "v3.0]-PS01" would
      # otherwise print a bare "--".
      #
      # Caveat, the same one BIPM records: "-" is both the intra-slug join and
      # the substitute, so two slugs differing ONLY in which non-slug character
      # they use collapse onto one MR string. The corpus has exactly one such
      # pair, the malformed "OpenC2-MQTT-v1.0] -CS01" spelled once with a
      # normal space and once with a non-breaking one — two spellings of one
      # document. Every genuinely distinct identifier keeps its own slug.
      def mr_sanitize(value)
        slug = value.to_s.downcase.gsub(/[^a-z0-9]+/, "-")
          .gsub(/\A-+|-+\z/, "")
        slug.empty? ? nil : slug
      end
    end
  end
end
