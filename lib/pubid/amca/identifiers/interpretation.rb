# frozen_string_literal: true

module Pubid
  module Amca
    module Identifiers
      # Interpretation identifier for ACMA interpretations
      # Examples:
      # - AMCA 99 JW Interp
      # - AMCA 204 – 1
      # - ANSI/AMCA 204 Interp
      class Interpretation < Identifier
        attribute :number, :string

        # See Publication: the hand-written keyword initializer bypassed lutaml,
        # costing this class its `_type`, its `publisher` default and the
        # serialization of `interpretation_code`.
        attribute :interpretation_code, :string

        key_value do
          map "interpretation_code", to: :interpretation_code
        end

        # The interpretation letter is what distinguishes one interpretation of
        # a standard from another ("AMCA 99 JW Interp" vs "AMCA 99 KB Interp" —
        # different documents, and #== agrees). It is in `==` and in `to_s`, so
        # it must reach the slug too, or three interpretations of standard 99
        # share one filename.
        def mr_number_with_part
          mr_join(super, interpretation_code&.to_s&.downcase)
        end

        def self.type
          { key: :interpretation, title: "Interpretation", short: "Interp" }
        end
      end
    end
  end
end
