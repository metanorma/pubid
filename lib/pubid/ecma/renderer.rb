# frozen_string_literal: true

module Pubid
  module Ecma
    # Human-readable renderer for ECMA identifiers.
    #
    # Produces strings like:
    #   "ECMA-411"           standard
    #   "ECMA-418-1"         standard with part
    #   "ECMA TR/101"        technical report
    #   "ECMA MEM/1970"      memento
    #   "ECMA-269 ed3 vol2"  with the edition and volume suffixes
    #
    # With `with_publisher: false` the leading ECMA token is dropped, yielding
    # "-411" / "TR/101" / "MEM/1970".
    class Renderer < ::Pubid::Renderers::Base
      PUBLISHER = "ECMA"

      # `with_edition` and `with_volume` default to TRUE — the inverse of
      # pubid's usual opt-in, deliberately. `Relaton::Index::Type#add_or_update`
      # keys on a BARE `id.to_s` and cannot pass options, so the default
      # rendering is what the index keys on, and it has to be unique per row.
      # With the edition omitted, all 22 editions of ECMA-74 collapsed onto one
      # key and 383 of the 804 published rows were dropped silently.
      #
      # Per-flavor divergence in these defaults is the established pattern:
      # Pubid::Tgpp defaults `with_publisher` to false and Pubid::W3c to true,
      # each for its own consumer's reason.
      def render(context: nil, with_edition: true, with_volume: true, **_opts)
        id = @id
        # Standard joins the publisher directly ("ECMA-411"); TR/MEM separate it
        # with a space ("ECMA TR/101"). type_prefix is nil only for standards.
        sep = id.type_prefix.nil? ? "" : " "
        core = id.type_prefix.nil? ? standard_core(id) : typed_core(id)
        result = with_publisher?(id) ? "#{PUBLISHER}#{sep}#{core}" : core
        result + suffixes(id, with_edition, with_volume)
      end

      private

      # " ed<edition>" then " vol<volume>", each only when the identifier
      # carries it and the caller has not opted out. The order is canonical:
      # the grammar accepts the volume only after the edition.
      def suffixes(id, with_edition, with_volume)
        out = +""
        out << " ed#{id.edition}" if with_edition && id.edition
        out << " vol#{id.volume}" if with_volume && id.volume
        out
      end

      # Standard: "-<number>[-<part>]".
      def standard_core(id)
        core = "-#{id.number}"
        id.part ? "#{core}-#{id.part}" : core
      end

      # Technical Report / Memento: "<TYPE>/<number>".
      def typed_core(id)
        "#{id.type_prefix}/#{id.number}"
      end

      def with_publisher?(id)
        id.with_publisher != false
      end
    end
  end
end
