# frozen_string_literal: true

module Pubid
  module Iana
    # Base class for every IANA identifier AND the flavor's parse/create entry
    # point. Concrete identifiers under Pubid::Iana::Identifiers descend from
    # this class, so a parsed IANA id is an instance of Pubid::Iana::Identifier.
    #
    # IANA entries are protocol registries, not numbered standards: the value is
    # a hierarchical registry slug (`registry` before the single "/", optional
    # `sub_registry` after it). Both are kept verbatim.
    #
    # The top-level slug is stored as `number` on the concrete leaf
    # (Identifiers::Registry) so it can serve as the relaton-index key; see the
    # long comment there for why the attribute lives on the leaf. `registry` is
    # a derived reader over it, so it is NOT a serialized key.
    class Identifier < ::Pubid::Identifier
      # The sub-registry slug (e.g. "lowpan_nhc"). nil for top registries; a nil
      # default means it is dropped from the serialized hash when absent.
      attribute :sub_registry, :string

      # Polymorphic type map for lutaml::Model key_value (de)serialization: maps
      # the single Registry subclass's polymorphic_name to its class name so a
      # stored hash rebuilds the correct identifier type via from_hash.
      IANA_TYPE_MAP = {
        "pubid:iana:registry" => "Pubid::Iana::Identifiers::Registry",
      }.freeze

      # Identifiers::Registry merges its own block mapping `number` on top of
      # this one. `number` is intentionally absent here: mapping it on the class
      # the leaf inherits from would re-declare the parent's Components::Code
      # attribute (see Identifiers::Registry).
      key_value do
        map "_type", to: :_type, polymorphic_map: IANA_TYPE_MAP
        map "sub_registry", to: :sub_registry
      end

      # Publisher is always "IANA". A plain constant (not a `publisher` method)
      # so it doesn't shadow the inherited lutaml `publisher` attribute, which
      # would otherwise fail serialization type validation.
      PUBLISHER = "IANA"

      # Render-time flag stashed by #to_s; when false, the "IANA " token is
      # dropped so callers can recover the bare index-key slug.
      attr_reader :with_publisher

      # The top-level registry slug. Derived from `number`, which is where it is
      # stored — a plain method is safe because `registry` is no longer a lutaml
      # attribute, so no generated accessor competes with it (the same shape as
      # Pubid::Ietf::Identifiers::Bcp#series).
      def registry
        number
      end

      # The rendered registry code, e.g. "_6lowpan-parameters/lowpan_nhc".
      def code
        sub_registry ? "#{registry}/#{sub_registry}" : registry
      end

      # Basic string representation. Delegates to the renderer. Always emits the
      # "IANA " token (the authoritative printed form) unless with_publisher is
      # false, in which case the bare slug is rendered.
      def to_s(with_publisher: true, **opts)
        @with_publisher = with_publisher
        render(format: :human, **opts)
      end

      # --- Machine-readable slug -------------------------------------------
      # The shared MrString renderer composes publisher/type/number/... from the
      # inherited attributes, none of which IANA populates: `publisher` is a
      # constant rather than an attribute (see PUBLISHER above) and the builder
      # sets no typed_stage. Without these two overrides every IANA identifier
      # rendered the empty MR string, so all of them collided on `to_mr_string`
      # and `to_slug` (issue #142) — and `to_slug` is used as a filename.
      #
      # Verified over the 3405 published relaton-data-iana rows: the resulting
      # slugs are all distinct and stay inside the documented [a-z0-9._-] MR
      # charset. Note that IANA slugs legitimately contain "_", which is MR's
      # supplement separator, so an IANA MR is not re-parseable by
      # Pubid::Parsers::MrString; uniqueness and filename-safety are what these
      # buy, not MR round-tripping.
      def mr_publisher
        PUBLISHER.downcase
      end

      def mr_number_with_part
        [number, sub_registry].compact.join(".").downcase
      end

      # The guard below has to cover this surface too: without it a nil number
      # renders the bare publisher token "iana" for every affected row, i.e. one
      # filename shared by all of them.
      def to_mr_string
        require_number!
        super
      end

      # The top-level slug moved from a `registry` key into `number` with no
      # alias, so a row serialized before that change deserializes with a nil
      # number and NO error: lutaml ignores unknown keys, and relaton's
      # Index::FileIO#id_supported? skips its round-trip check for concrete
      # subclasses (every IANA id is an Identifiers::Registry). Failing loudly
      # at render time is the only thing that surfaces a stale index.
      #
      # It is called from all three identity surfaces — to_s (via Renderer),
      # to_urn (via UrnGenerator) and to_mr_string — because guarding only one
      # still lets every stale row collide on the other two ("urn:iana:",
      # "iana"), which is the silent overwrite this whole change exists to
      # prevent.
      def require_number!
        return unless number.nil? || number.to_s.empty?

        raise ArgumentError,
              "Cannot render #{self.class} with an empty number " \
              "(a pre-`number` index row stored the registry slug under " \
              "`registry`; regenerate the index)"
      end

      # from_hash is the shared polymorphic dispatch on Pubid::Identifier;
      # IANA_TYPE_MAP remains as the key_value polymorphic_map.

      # Parse an IANA identifier string into an identifier object
      # @param identifier [String] The IANA identifier string to parse
      # @return [Identifier] The appropriate identifier object
      def self.parse(identifier)
        if identifier.length > Pubid::MAX_INPUT_LENGTH
          raise ArgumentError, Pubid::INPUT_TOO_LONG_MESSAGE
        end

        parsed = Parser.parse(identifier)
        Builder.build(parsed)
      rescue Parslet::ParseFailed => e
        raise "Failed to parse IANA identifier '#{identifier}': #{e.message}"
      end
    end
  end
end
