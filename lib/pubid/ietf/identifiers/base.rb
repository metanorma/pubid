# frozen_string_literal: true

module Pubid
  module Ietf
    # Base class for every IETF identifier AND the flavor's parse/create entry
    # point (mirrors Pubid::Jis::Identifier). Concrete identifiers under
    # Pubid::Ietf::Identifiers descend from this class, so a parsed IETF id is
    # an instance of Pubid::Ietf::Identifier.
    #
    # All families are flat, supplement-free, and use plain string attributes.
    # Those attributes are declared on the LEAVES by Identifiers::Serialization
    # (see the determinism note there — never re-add `attribute :number` here):
    #   * Rfc            -> number ("2119")
    #   * Bcp/Std/Fyi    -> number ("3") + a derived `series` reader
    #   * InternetDraft  -> number ("draft-giuliano-treedn") + optional version
    class Identifier < ::Pubid::Identifier
      # Polymorphic type map for lutaml::Model key_value (de)serialization: maps
      # each subclass's polymorphic_name to its class name so a stored hash
      # rebuilds the correct identifier type via the shared from_hash dispatch.
      IETF_TYPE_MAP = {
        "pubid:ietf:rfc" => "Pubid::Ietf::Identifiers::Rfc",
        "pubid:ietf:bcp" => "Pubid::Ietf::Identifiers::Bcp",
        "pubid:ietf:std" => "Pubid::Ietf::Identifiers::Std",
        "pubid:ietf:fyi" => "Pubid::Ietf::Identifiers::Fyi",
        "pubid:ietf:internet-draft" =>
          "Pubid::Ietf::Identifiers::InternetDraft",
      }.freeze

      # NOTE: no `key_value` block here on purpose. The mapping lives on the
      # leaves (Identifiers::Serialization); a block on this shared parent would
      # be inherited-and-merged by every leaf and re-emit keys the leaf did not
      # declare.

      # Publisher is always "IETF". A plain constant (not a `publisher` method)
      # so it doesn't shadow the inherited lutaml `publisher` attribute, which
      # would otherwise fail serialization type validation.
      PUBLISHER = "IETF"

      # Basic string representation. Delegates to the flavor renderer.
      def to_s(**opts)
        render(format: :human, **opts)
      end

      # from_hash is the shared polymorphic dispatch on Pubid::Identifier; the
      # IETF_TYPE_MAP above serves as its key_value polymorphic_map.

      # Parse an IETF identifier string into the appropriate identifier object.
      # @param identifier [String] the IETF identifier string to parse
      # @return [Identifier] the concrete identifier object
      # @raise [ArgumentError] if the input exceeds Pubid::MAX_INPUT_LENGTH
      # @raise [RuntimeError] if parsing fails
      def self.parse(identifier)
        # Inline length guard (CodeQL rb/polynomial-redos barrier) — must be
        # the first statement. This class-level funnel is what relaton reaches
        # directly through `pubid_class: ::Pubid::Ietf::Identifier`, so it
        # cannot rely on the guard in Pubid::Ietf.parse.
        if identifier.length > Pubid::MAX_INPUT_LENGTH
          raise ArgumentError, Pubid::INPUT_TOO_LONG_MESSAGE
        end

        parsed = Parser.parse(identifier)
        Builder.build(parsed)
      rescue Parslet::ParseFailed => e
        raise "Failed to parse IETF identifier '#{identifier}': #{e.message}"
      end
    end
  end
end
