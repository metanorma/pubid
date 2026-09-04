# frozen_string_literal: true

module Pubid
  module Ecma
    # Base class for every ECMA identifier AND the flavor's parse entry point —
    # mirrors Pubid::Jis::Identifier. Concrete identifiers under
    # Pubid::Ecma::Identifiers descend from this class, so a parsed ECMA id is
    # an instance of Pubid::Ecma::Identifier. ECMA has no supplement layer.
    # KEEP THIS CLASS BODY IN ONE FILE, AND NEVER REOPEN IT. `number`, `part`
    # and `edition` below redeclare attributes the parent ::Pubid::Identifier
    # types as components, which resolves nondeterministically under
    # multi-flavor load if a subclass can snapshot a half-built attribute
    # table. lutaml deep-dups the parent table into each subclass at
    # class-definition time, and Ruby resolves this superclass constant to
    # completion before opening any leaf body — so a single, never-reopened
    # body is what makes the redeclaration safe. (The W3C precedent; IEEE's
    # split base is the counter-shape.)
    class Identifier < ::Pubid::Identifier
      # The document number as a string (preserves any leading zeros). `part`
      # is only present for standards that split into parts (e.g. ECMA-418-1).
      attribute :number, :string
      attribute :part, :string
      # Edition is relaton's `:ed:` (the index stores {:id, :ed, :vol} and the
      # YAML has edition.content). It is part of the printed identifier: the
      # relaton index keys on a bare `to_s`, so without it all 22 editions of
      # ECMA-74 collapse onto one key. An optional string, because decimal
      # editions like "5.1" occur. No default, so it drops from the hash when
      # unset.
      attribute :edition, :string
      # Volume is relaton's `:vol:`. Only ECMA-269 edition 3 uses it: its four
      # volumes share one docidentifier AND one title, so the volume is the only
      # thing that distinguishes those four index rows. A plain string, the
      # `number`/`edition` precedent, so it round-trips verbatim.
      attribute :volume, :string

      # Polymorphic type map for lutaml::Model key_value (de)serialization:
      # maps each subclass's polymorphic_name to its class name so a stored
      # hash rebuilds the correct identifier type via from_hash.
      ECMA_TYPE_MAP = {
        "pubid:ecma:standard" => "Pubid::Ecma::Identifiers::Standard",
        "pubid:ecma:technical-report" =>
          "Pubid::Ecma::Identifiers::TechnicalReport",
        "pubid:ecma:memento" => "Pubid::Ecma::Identifiers::Memento",
      }.freeze

      key_value do
        map "_type", to: :_type, polymorphic_map: ECMA_TYPE_MAP
        map "number", to: :number
        map "part", to: :part
        map "edition", to: :edition
        map "volume", to: :volume
      end

      # Publisher is always "ECMA". A plain constant (not a `publisher` method)
      # so it doesn't shadow the inherited lutaml `publisher` attribute, which
      # would otherwise fail serialization type validation.
      PUBLISHER = "ECMA"

      # Whether the last `to_s` should include the "ECMA" publisher token.
      attr_reader :with_publisher

      # Basic string representation. Delegates to renderer. `with_publisher:
      # false` drops the ECMA token (e.g. "-411", "TR/84").
      #
      # The edition and volume suffixes are rendered by DEFAULT and are opted
      # out of with `to_s(with_edition: false, with_volume: false)`. Both flags
      # ride in `opts` to the renderer, which owns their defaults — see
      # Pubid::Ecma::Renderer for why the default is "with".
      def to_s(with_publisher: true, **opts)
        @with_publisher = with_publisher
        render(format: :human, **opts)
      end

      # Type token that precedes the number ("TR"/"MEM"), or nil for standards.
      # Overridden by each concrete identifier class.
      def type_prefix
        nil
      end

      # ECMA keeps its publisher in the PUBLISHER constant rather than the
      # inherited `publisher` attribute, so the base hook — `publisher&.to_s` —
      # is nil and every ECMA slug would lose its "ecma." segment.
      def mr_publisher
        PUBLISHER.downcase
      end

      # The Builder picks an identifier class; it never sets a `typed_stage`,
      # so the base hook is always nil. Without this, "ECMA-101" and
      # "ECMA TR/101" produce the same slug — and `to_slug` is an output
      # filename, so one document would overwrite the other.
      def mr_type
        type_prefix&.downcase
      end

      # ECMA's `edition` is a plain :string ("3", "5.1"), not a
      # Components::Edition, so the base hook's `edition&.number` raises
      # NoMethodError on every edition-bearing identifier.
      def mr_edition
        mr_marker("ed", edition)
      end

      # Volume is identity-bearing (ECMA-269 ed3 vol1..vol4 are four distinct
      # documents), so it must reach the MR string as well as `to_s` and the
      # URN. Fills the shared `mr_volume` slot in Renderers::MrString.
      def mr_volume
        mr_marker("vol", volume)
      end

      # Parse an ECMA identifier string into an identifier object.
      # @param identifier [String] The ECMA identifier string to parse
      # @return [Identifier] The appropriate identifier object
      # @raise [ArgumentError] If the input exceeds MAX_INPUT_LENGTH
      # @raise [RuntimeError] If parsing fails
      def self.parse(identifier)
        if identifier.length > Pubid::MAX_INPUT_LENGTH
          raise ArgumentError, Pubid::INPUT_TOO_LONG_MESSAGE
        end

        parsed = Parser.parse(identifier)
        Builder.build(parsed)
      rescue Parslet::ParseFailed => e
        raise "Failed to parse ECMA identifier '#{identifier}': #{e.message}"
      end

      private

      # Renderers::MrString joins SEGMENTS with ".", so a dot inside one would
      # break the documented segment structure — hence "ed5-1" for edition
      # "5.1". Sanitising by CHARSET rather than by an enumerated escape list,
      # so a value added later cannot leak an unsafe character (the BIPM
      # `mr_slug` precedent).
      #
      # The MR may be lossy here because nothing parses an ECMA MR back
      # (`Parsers::MrString::FLAVOR_MAP` has no ECMA entry). The URN, which
      # UrnParser inverts, keeps the dot instead.
      def mr_marker(label, value)
        return nil if value.nil? || value.to_s.empty?

        "#{label}#{value.to_s.downcase.gsub(/[^a-z0-9]+/, '-')}"
      end
    end
  end
end
