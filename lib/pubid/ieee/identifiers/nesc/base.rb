# frozen_string_literal: true

require "lutaml/model"

module Pubid
  module Ieee
    module Identifiers
      module Nesc
        # Base class for National Electrical Safety Code (NESC) identifiers
        #
        # NESC is published by IEEE Standards Association and covers electrical
        # safety standards for utilities and communication systems.
        #
        # @example Standard format
        #   nesc = Pubid::Ieee.parse("C2-1997 National Electric Safety Code")
        #   nesc.code.value  # => "C2"
        #   nesc.year.year   # => 1997
        #
        # @example Handbook format
        #   nesc = Pubid::Ieee.parse("2017 NESC Handbook, Premier Edition")
        #   nesc.year.year   # => 2017
        #   nesc.variant     # => "Handbook"
        #   nesc.edition     # => "Premier Edition"
        class Base < Lutaml::Model::Serializable
          attribute :code, Pubid::Ieee::Components::Code # "C2" code designation
          attribute :year, Pubid::Components::Date # Publication year
          attribute :variant, :string              # Handbook, Redline, etc.
          attribute :edition, :string              # Edition notation
          attribute :draft, :boolean               # Draft flag
          attribute :month, :string                # For draft identifiers
          # Registered-trademark "(R)" after the full name or abbreviation
          attribute :registered, :boolean
          # Whether the "(NESC)"/"(NESC(R))" abbreviation suffix was present
          attribute :abbr_suffix, :boolean
          # Registered-trademark "(R)" inside the "(NESC(R))" suffix
          attribute :abbr_suffix_registered, :boolean

          # Publisher portion for NESC identifiers
          #
          # @return [String] Always returns "NESC"
          def publisher_portion
            "NESC"
          end

          # Rendering for year-first NESC identifiers (the C2-code standard form
          # overrides this in Nesc::Standard). IEEE catalogues the year-first
          # editions with the "IEEE Std" prefix, so it is prepended here.
          #
          # @param trademark [Boolean] append the IEEE trademark symbol (™/®)
          # @return [String] String representation
          def to_s(trademark: false)
            result = "IEEE Std #{year.year} #{name_portion}"
            result += Pubid::Ieee.trademark_symbol(result) if trademark
            result
          end

          # The document-name portion, including the registered marks and the
          # optional "(NESC(R))" abbreviation suffix.
          #
          # @return [String] e.g. "National Electrical Safety Code(R) (NESC(R))"
          def name_portion
            name = "National Electrical Safety Code"
            name += "(R)" if registered
            if abbr_suffix
              suffix = "NESC"
              suffix += "(R)" if abbr_suffix_registered
              name += " (#{suffix})"
            end
            name
          end
        end
      end
    end
  end
end
