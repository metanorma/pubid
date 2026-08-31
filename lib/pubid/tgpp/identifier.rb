# frozen_string_literal: true

module Pubid
  module Tgpp
    # Base class for every 3GPP identifier AND the flavor's parse entry point —
    # mirrors Pubid::Jis::Identifier. Concrete identifiers under
    # Pubid::Tgpp::Identifiers descend from this class, so a parsed 3GPP id is
    # an instance of Pubid::Tgpp::Identifier.
    class Identifier < ::Pubid::Identifier
      # The dotted core (e.g. "23.207") kept as a string to preserve leading
      # zeros. `number` overrides the base Components::Code attribute.
      attribute :number, :string
      # Optional letter suffix directly after the number: "U", "dcs", "ext"…
      attribute :suffix, :string
      # 1–2 hyphen parts (e.g. "26.171-1", "29.198-04-1"); strings preserve any
      # zero-padding.
      attribute :parts, :string, collection: true
      # Raw release token, stored verbatim: "REL-4", "Ph1", "UMTS",
      # "Release 2000".
      attribute :release, :string
      # Three-part version string, e.g. "2.0.0".
      attribute :version, :string

      # Polymorphic type map for lutaml::Model key_value (de)serialization.
      # Keys are the `pubid:3gpp:…` names produced by polymorphic_name (below).
      TGPP_TYPE_MAP = {
        "pubid:3gpp:technical-report" =>
          "Pubid::Tgpp::Identifiers::TechnicalReport",
        "pubid:3gpp:technical-specification" =>
          "Pubid::Tgpp::Identifiers::TechnicalSpecification",
      }.freeze

      key_value do
        map "_type", to: :_type, polymorphic_map: TGPP_TYPE_MAP
        map "number", to: :number
        map "suffix", to: :suffix
        map "parts", to: :parts
        map "release", to: :release
        map "version", to: :version
      end

      # Publisher token. A plain constant (not a `publisher` method) so it does
      # not shadow the inherited lutaml `publisher` attribute.
      PUBLISHER = "3GPP"

      # The auto-derived polymorphic name would be "pubid:tgpp:…" (from the
      # module constant). Force the "3gpp" segment so the `_type` tag matches
      # the relaton flavor name and TGPP_TYPE_MAP.
      def self.polymorphic_name
        super&.sub(/\Apubid:tgpp:/, "pubid:3gpp:")
      end

      # Rendering flag: whether to prefix the string with "3GPP ". Transient
      # (not serialized). #to_s sets it, renders, then resets it to false in an
      # ensure block, so a subsequent bare #render defaults to no publisher and
      # the flag never leaks past the to_s call that set it.
      attr_reader :with_publisher

      # The rendered document code, e.g. "29.198-04-1" (number+suffix+parts).
      def code
        result = "#{number}#{suffix}"
        result += parts.map { |p| "-#{p}" }.join if parts&.any?
        result
      end

      # Basic string representation. Delegates to the :human renderer. Default
      # omits the "3GPP " publisher token (matches the relaton index id);
      # `to_s(with_publisher: true)` emits the printed "3GPP TS …" form.
      def to_s(with_publisher: false, **opts)
        @with_publisher = with_publisher
        render(format: :human, **opts)
      ensure
        @with_publisher = false
      end

      # Parse a 3GPP identifier string into an identifier object.
      #
      # Let Parslet::ParseFailed propagate on a bad reference (matching ISO and
      # ETSI), so relaton-cli's `rescue Parslet::ParseFailed` fetch handler
      # catches it instead of a bare RuntimeError. The length guard keeps its
      # ArgumentError — that is a different failure (input too long, not
      # unparseable) and it is the ReDoS barrier.
      #
      # @param identifier [String] The 3GPP identifier string to parse
      # @return [Identifier] The appropriate identifier object
      def self.parse(identifier)
        if identifier.length > Pubid::MAX_INPUT_LENGTH
          raise ArgumentError, Pubid::INPUT_TOO_LONG_MESSAGE
        end

        parsed = Parser.parse(identifier)
        Builder.build(parsed)
      end
    end
  end
end
