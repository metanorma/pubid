# frozen_string_literal: true

module Pubid
  module Astm
    module Identifiers
      class Adjunct < SingleIdentifier
        include CodeNumber

        # An adjunct carries no code at all — its whole identity is the
        # designation ("ADJD2148"). relaton-index keys on
        # `id.root.number.to_s`, so the designation IS the number here, the
        # same reasoning that makes a registry slug IANA's number and a draft
        # slug IETF's.
        #
        # It is stored in `number` itself rather than in a separate
        # `designation` attribute shadowed by a `def number`. Two reasons, both
        # from CLAUDE.md: defining a `#number` method alongside the attribute is
        # the construct that corrupts lutaml's accessor resolution, and keeping
        # both columns made `to_hash` emit the same string twice
        # ({"number" => "D2148", "designation" => "D2148"}) — the duplication
        # the BIPM note warns against. The builder assigns `number` and the
        # renderer reads it; nothing else referenced `designation`.
        attribute :ea_suffix, :boolean       # -EA
        attribute :dvd_suffix, :boolean      # DVD
      end
    end
  end
end
