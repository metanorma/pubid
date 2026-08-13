# frozen_string_literal: true

module Pubid
  module Ieee
    module Aiee
      # AIEE identifiers (American Institute of Electrical Engineers: 1884-1963).
      #
      # Reparented onto Pubid::Ieee::Identifier + the CodeNumber mixin so AIEE
      # shares the flat split-column serialization (number/prefix/parts/
      # separator), a polymorphic `_type`, `#root`, and from_hash routing with
      # every other IEEE type. Previously it descended from bare
      # Lutaml::Model::Serializable and serialized a nested `code` object with no
      # `_type`, so Pubid::Ieee::Identifier.from_hash could not route back to
      # this class and dropped the code entirely — every AIEE row failed the
      # relaton index-v2 round-trip gate and had a nil `root.number`.
      #
      # The date long-form separator is named `date_separator` (not `separator`)
      # to avoid colliding with the CodeNumber code-part `separator`.
      class Identifier < Pubid::Ieee::Identifier
        include Pubid::Ieee::Identifiers::CodeNumber

        attribute :publisher, :string, default: -> { "AIEE" }
        # AIEE carries no implicit type keyword, so override the base's "Std"
        # default (else "AIEE 11-1937" would render as "AIEE Std 11-1937").
        attribute :type, :string, default: -> {}
        attribute :date_separator, :string  # "," or "." for long-form dates
        attribute :original_format, :string # "short"/"long" (preserves parsed format)

        # A distinct polymorphic name so from_hash routes to AIEE. The derived
        # default (last name segment "Identifier") would be
        # "pubid:ieee:identifier", colliding with the base class.
        def self.polymorphic_name
          "pubid:ieee:aiee"
        end

        # Parse AIEE identifier string
        def self.parse(input)
          parsed = Parser.new.parse(input)
          Builder.new.build(parsed)
        end

        def to_s(date_format: nil, trademark: false)
          result = [publisher]
          result << type if type
          result << code.to_s if code

          base = result.join(" ")

          # IEEE attaches the mark to the number, before the date suffix
          # ("AIEE No 13™-1930").
          if trademark
            base += Pubid::Ieee.trademark_symbol_for(code_obj&.number,
                                                     code_obj&.prefix,
                                                     publishers: [publisher])
          end

          # Priority: explicit parameter > original_format > format auto-detect
          format = date_format&.to_s || original_format
          format ||= month || date_separator ? "long" : "short"

          if year
            case format
            when "short", :short
              base += "-#{year}"
            when "long", :long
              sep = date_separator || "," # Default to comma for long form
              base += "#{sep} #{"#{month} " if month}#{year}"
            else
              base += if date_separator
                        "#{date_separator} #{"#{month} " if month}#{year}"
                      elsif month
                        ", #{month} #{year}"
                      else
                        "-#{year}"
                      end
            end
          end

          # The descriptive relationships narrative is deliberately kept out of
          # to_s (an identifier string must stay bounded — it is used as a
          # document number/filename downstream). It stays reachable on
          # `relationships`.

          base
        end
      end
    end
  end
end
