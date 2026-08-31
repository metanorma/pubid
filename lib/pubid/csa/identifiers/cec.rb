# frozen_string_literal: true

module Pubid
  module Csa
    module Identifiers
      # Canadian Electrical Code (CEC) identifier
      # Pattern: CSA C22.{2,3,4,6} NO. {number}:{year}
      # Examples: CSA C22.2 NO. 286:23, CSA C22.3 NO. 7:20
      #
      # The "NO." indicates a numbered standard within the C22.x series
      # and must be preserved (not normalized) as a semantic component.
      class Cec < SingleIdentifier
        attribute :cec_part, Components::Code      # C22.2, C22.3, C22.4, C22.6
        attribute :no_number, Components::Code     # Number after NO.

        # Merged with SingleIdentifier's block (lutaml combines an inherited
        # key_value block with a subclass one), so this adds only the half of
        # the code that Cec keeps separately.
        key_value do
          map "cec_part",
              with: { to: :cec_part_to_kv, from: :cec_part_from_kv }
        end

        def cec_part_to_kv(model, doc)
          emit_kv(doc, "cec_part", model.cec_part)
        end

        def cec_part_from_kv(model, value)
          model.cec_part = Components::Code.new(value: value.to_s)
        end

        # The document code, synthesised from its two halves:
        # cec_part + "-" + no_number (e.g. "C22.2-1"). This is the index key.
        #
        # It shadows the reader lutaml generates for the inherited `number`
        # attribute, which is safe because Cec declares no `number` of its own
        # — the ITU precedent (itu/identifiers/base.rb). `cec_part` and
        # `no_number` are themselves serialized, so from_hash reproduces the
        # synthesised value.
        #
        # Deliberately NOT memoised: `@number` is the very ivar lutaml uses to
        # store the inherited attribute, so caching there would both discard a
        # value assigned through the generated writer and go stale if
        # `cec_part`/`no_number` were reassigned — and `number` is the relaton
        # index key. The concatenation is trivial, so there is nothing to save.
        def number
          return nil unless cec_part && no_number

          Components::Code.new(value: "#{cec_part.value}-#{no_number.value}")
        end
      end
    end
  end
end
