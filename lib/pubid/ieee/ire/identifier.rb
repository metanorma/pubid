# frozen_string_literal: true

require "lutaml/model"

module Pubid
  module Ieee
    module Ire
      # IRE identifiers (Institute of Radio Engineers: 1912-1963).
      #
      # Reparented onto Pubid::Ieee::Identifier + the CodeNumber mixin for the
      # same reasons AIEE was (see Pubid::Ieee::Aiee::Identifier): descending
      # from bare Lutaml::Model::Serializable left IRE without `#root` (relaton
      # keys its index on `id.root.number.to_s` -> NoMethodError), without a
      # polymorphic `_type` (so `from_hash` could not route back), and — because
      # an IRE object was not a ::Pubid::Identifier — unassignable to
      # Identifiers::AdoptedStandard#adopted_identifiers, which raised
      # Lutaml::Model::IncorrectModelError on `to_hash` for the IRE-adopted
      # forms ("IEEE Std 159-1972 (52 IRE 7 S2)").
      #
      # The document designation ("7.S2") is carried in the shared `code_obj`
      # and serialized as the flat split columns (number/prefix/parts/
      # separator); the publication year uses the base's plain `:string` `year`
      # (IRE previously declared its own `:integer` one, which would collide).
      class Identifier < Pubid::Ieee::Identifier
        include Pubid::Ieee::Identifiers::CodeNumber

        attribute :publisher, :string, default: -> { "IRE" }
        # IRE spells its type word out when present ("Trans.", "Standard",
        # "Std") and omits it otherwise, so the base's "Std" default must go —
        # else "52 IRE 7.S2" would render as "52 IRE Std 7.S2".
        attribute :type, :string, default: -> {}

        # A distinct polymorphic name so from_hash routes to IRE. The derived
        # default (last name segment "Identifier") would be
        # "pubid:ieee:identifier", colliding with the base class.
        def self.polymorphic_name
          "pubid:ieee:ire"
        end

        # Parse IRE identifier string
        def self.parse(input)
          parsed = Parser.new.parse(input)
          builder = Builder.new
          builder.build(parsed)
        end

        def to_s(trademark: false)
          # Year comes FIRST in IRE format - render as 2-digit short year
          result = [(short_year if year), publisher, type, code&.to_s]
            .compact.join(" ")
          # The code is the last token, so the end of the string already *is*
          # the code boundary — but the symbol is picked from the code, not by
          # scanning the string (which starts with the year).
          if trademark
            result += Pubid::Ieee.trademark_symbol_for(code_obj&.number,
                                                       code_obj&.prefix,
                                                       publishers: [publisher])
          end
          result
        end

        private

        # IRE prints the publication year first, abbreviated to two digits for
        # the 20th century ("1952" => "52").
        def short_year
          value = year.to_i
          (value.between?(1900, 1999) ? value - 1900 : value).to_s
        end
      end
    end
  end
end
