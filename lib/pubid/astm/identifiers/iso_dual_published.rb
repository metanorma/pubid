# frozen_string_literal: true

module Pubid
  module Astm
    module Identifiers
      # IsoDualPublished represents ASTM standards that are dual-published with ISO
      #
      # SEMANTIC NOTE: ISO/ASTM dual-published standards (typically 5xxxx series)
      # - ASTM version: ASTM 52303-24e1 (e1 = edition 1, not "E" prefix)
      # - ISO version: ISO/ASTM 52303:2024
      #
      # Distinguishing feature: Starts with digit (typically 5xxxx series)
      # These are ASTM's version of standards jointly developed with ISO
      class IsoDualPublished < Standard
        # Re-included even though Standard already does. DO NOT "clean this
        # up" — it compiles fine without it, passes most tests, and silently
        # reintroduces the multi-flavor `number` determinism landmine for this
        # class alone, visible only under the full suite.
        #
        # Two Ruby facts make the repeat both necessary and safe:
        #   * `included(base)` fires on EVERY `include` call, so this gives
        #     IsoDualPublished its own `attribute :number` resolved against its
        #     own table rather than a snapshot inherited from Standard;
        #   * `Module#include` does NOT re-insert a module already present via
        #     a superclass, so CodeNumber keeps the ancestor position Standard
        #     gave it — still BELOW Standard. That is what lets
        #     Standard#mr_number_with_part's `super` reach CodeNumber's
        #     implementation instead of being shadowed here.
        include CodeNumber

        # Inherits all behavior from Standard:
        # - sub_year (a, b, c)
        # - reapproval ((2023))
        # - edition (e1)
        # - code (number without letter prefix)
        # - year (2024 → 24)

        # No additional attributes needed - same structure as Standard
        # The semantic difference is the classification itself

        # Rendering is identical to Standard
        # Example: ASTM 52303-24e1

        # Convert to ISO/ASTM dual-published format.
        # Uses Pubid::Iso.build so this flavor never reaches into ISO's
        # internal class hierarchy.
        # @return [Pubid::Iso::Identifier] ISO version
        #
        # @example Convert ASTM to ISO format
        #   astm = Pubid::Astm.parse("ASTM 52303-24e1")
        #   iso = astm.to_iso_identifier
        #   iso.to_s # => "ISO/ASTM 52303:2024"
        def to_iso_identifier
          Pubid::Iso.build(
            type: :is,
            publisher: "ISO",
            copublishers: ["ASTM"],
            number: code&.number,
            year: year&.to_s,
          )
        end
      end
    end
  end
end
