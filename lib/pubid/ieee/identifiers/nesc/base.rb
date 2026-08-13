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
        #   nesc.code.number # => "2"   (prefix "C")
        #   nesc.year        # => "1997"
        #
        # @example Handbook format
        #   nesc = Pubid::Ieee.parse("2017 NESC Handbook, Premier Edition")
        #   nesc.year        # => "2017"
        #   nesc.variant     # => "Handbook"
        #   nesc.edition     # => "Premier Edition"
        #
        # Reparented onto Pubid::Ieee::Identifier (it used to descend from bare
        # Lutaml::Model::Serializable) so NESC shares `#root`, a polymorphic
        # `_type` and from_hash routing with every other IEEE type — see
        # Pubid::Ieee::Aiee::Identifier for the same migration. Three
        # attributes were reconciled against the base to avoid type collisions:
        #
        #   `code`  -> travels as the runtime `code_obj` (base #code returns
        #              it); the concrete leaves serialize the flat split
        #              columns via the CodeNumber mixin.
        #   `year`  -> the base's plain `:string` year (was a
        #              Pubid::Components::Date), matching IEEE's scalar-date
        #              convention. `nesc.year` is now "2017", not a component.
        #   `draft` -> dropped; the base declares a `:string` `draft` (the draft
        #              *designator*), so a boolean here would corrupt it. Test
        #              draft-ness with `#draft?` / the Nesc::Draft class.
        #
        # This class is abstract and enforces it in #initialize: the builder
        # always instantiates a concrete leaf (Nesc::Edition for the plain
        # year-first form), because only leaves may redefine `number` as a
        # :string (see the CodeNumber mixin) and only leaves declare the
        # NESC-specific `polymorphic_name` that from_hash routes on.
        class Base < Pubid::Ieee::Identifier
          attribute :variant, :string # Handbook, Redline, etc.
          # Registered-trademark "(R)" after the full name or abbreviation
          attribute :registered, :boolean
          # Whether the "(NESC)"/"(NESC(R))" abbreviation suffix was present
          attribute :abbr_suffix, :boolean
          # Registered-trademark "(R)" inside the "(NESC(R))" suffix
          attribute :abbr_suffix_registered, :boolean

          # Guards the abstract contract — see the class docs. Ruby has no
          # `abstract`, and an instantiated Base would carry the derived
          # `_type` "pubid:ieee:base" (which from_hash cannot resolve back to
          # NESC) and a nil `number` (the empty relaton index key).
          def initialize(args = {}, **kwargs)
            if instance_of?(Base)
              raise NotImplementedError,
                    "#{self.class} is abstract; instantiate a concrete NESC " \
                    "type (Standard, Edition, Handbook, Redline, Draft)"
            end

            super
          end

          # Publisher portion for NESC identifiers
          #
          # @return [String] Always returns "NESC"
          def publisher_portion
            "NESC"
          end

          # Whether this is a draft of the code. NESC has no `draft` attribute
          # of its own (the base's `draft` is the draft designator string), so
          # draft-ness lives in the class.
          #
          # @return [Boolean]
          def draft?
            is_a?(Nesc::Draft)
          end

          # Rendering for year-first NESC identifiers (the C2-code standard form
          # overrides this in Nesc::Standard). IEEE catalogues the year-first
          # editions with the "IEEE Std" prefix, so it is prepended here.
          #
          # @param trademark [Boolean] append the IEEE trademark symbol (™/®)
          # @return [String] String representation
          def to_s(trademark: false)
            result = ["IEEE Std", year, name_portion].compact.join(" ")
            result += trademark_symbol if trademark
            result
          end

          # Trademark symbol for this document's own code. A NESC string starts
          # with the publication *year*, so the string-scanning
          # Pubid::Ieee.trademark_symbol would pick the wrong field — an
          # edition year of 2030 would silently render ®.
          #
          # @return [String] "®" or "™"
          def trademark_symbol
            Pubid::Ieee.trademark_symbol_for(code_obj&.number,
                                             code_obj&.prefix,
                                             publishers: [publisher])
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
