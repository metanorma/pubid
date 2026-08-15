# frozen_string_literal: true

module Pubid
  module Itu
    module Identifiers
      # Corrigendum identifier (Cor.)
      # Pattern: "ITU-T Z.100 (1999) Cor. 1 (10/2001)"
      # Can be corrigendum of annex: "ITU-T G.729 Annex E (1998) Cor. 1 (02/2000)"
      # A "Technical Corrigendum" — ITU's own spelling on 158 relaton-data-itu
      # records ("ITU-T H.222.0 (1995) Technical Cor. 1 (02/1998)"). It is a
      # distinct printed identifier from a plain "Cor. 1", so the qualifier is
      # preserved as a flag and rendered back rather than normalized away.
      # Named for the rarer form, so `false` is stripped from `to_hash` and no
      # existing serialized Corrigendum row gains a key.
      class Corrigendum < Supplement
        attribute :technical, :boolean, default: -> { false }

        key_value do
          map "technical", to: :technical
        end

        def to_s
          render_supplement(technical ? "Technical Cor." : "Cor.")
        end

        # `super` already enforces instance_of?(self.class), so this only has
        # to add the qualifier — "Cor. 1" and "Technical Cor. 1" of one base
        # are different documents.
        def ==(other)
          super && technical == other.technical
        end
      end
    end
  end
end
