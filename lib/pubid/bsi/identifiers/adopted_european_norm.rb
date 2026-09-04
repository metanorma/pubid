# frozen_string_literal: true

module Pubid
  module Bsi
    module Identifiers
      # AdoptedEuropeanNorm wraps CEN identifiers
      # Example: "BS EN 10077-1:2006" where EN 10077-1:2006 is a CEN identifier object
      # Example: "BS EN ISO 8601:2019" where EN ISO 8601:2019 is a CEN AdoptedEuropeanNorm wrapping ISO
      class AdoptedEuropeanNorm < BritishStandard
        attribute :adopted_identifier, ::Pubid::Identifier, polymorphic: true # CEN object
        attribute :edition, :string
        attribute :translation_lang, :string
        attribute :translation_upper, :string
        attribute :translation_suffix_type, :string # "version" or "Translation"
        attribute :reaffirmation_year, :string # For "(R2004)" notation
        attribute :expert_commentary, :boolean
        attribute :expert_commentary_topic, :string

        # Override self.type to return nil so this polymorphic wrapper is not
        # registered as a base type. Inherits `:bs` from BritishStandard which
        # would otherwise shadow it in Bsi.locate_type(:bs) auto-discovery.
        # AdoptedEuropeanNorm is constructed explicitly by the builder, not
        # selected by type-code lookup.
        def self.type
          nil
        end

        # Walk to the adopted document for the relaton-index key.
        #
        # The `#number` delegation below is not enough on its own: a
        # "DD ENV ISO 11079:1999" adopts a CenCenelec EuropeanPrestandard,
        # which is ITSELF a wrapper around the ISO standard, so the delegation
        # returned that wrapper's own (nil) number and the chain died one level
        # short. `#root` recurses, so it reaches the ISO standard however many
        # adoption layers sit in between.
        def root
          adopted_identifier ? adopted_identifier.root : self
        end

        # Delegate common methods to adopted identifier
        def number
          adopted_identifier&.number
        end

        def year
          adopted_identifier&.year if adopted_identifier&.methods&.include?(:year)
        end

        def date
          adopted_identifier&.date if adopted_identifier&.methods&.include?(:date)
        end

        def parts
          adopted_identifier&.parts if adopted_identifier&.methods&.include?(:parts)
        end

        def part
          adopted_identifier&.part if adopted_identifier&.methods&.include?(:part)
        end

        def subpart
          adopted_identifier&.subpart if adopted_identifier&.methods&.include?(:subpart)
        end
      end
    end
  end
end
