# frozen_string_literal: true

module Pubid
  module Ieee
    module Nesc
      # Builder for NESC identifier objects
      #
      # Transforms parsed hash into appropriate NESC identifier class instances.
      # Determines the correct identifier type based on parsed attributes and
      # constructs the object with proper components.
      #
      # @example Build standard NESC
      #   builder = Builder.new
      #   parsed = { code: "C2", year: "1997" }
      #   identifier = builder.build(parsed)
      #   # => #<Pubid::Ieee::Identifiers::Nesc::Standard>
      #
      # @example Build handbook
      #   parsed = { year: "2017", variant: "Handbook", edition: "Premier Edition" }
      #   identifier = builder.build(parsed)
      #   # => #<Pubid::Ieee::Identifiers::Nesc::Handbook>
      class Builder
        # The NESC's own designation (ANSI/IEEE C2). Used as the index code for
        # the year-first forms, which print no code of their own.
        #
        # CAVEAT: this files the whole NESC family — including the Handbook and
        # Redline, which are companions of the code rather than the code itself
        # — under one `prefix "C"` + `number "2"` index key. That is deliberate:
        # relaton narrows on `root.number` and then matches the full hash, so
        # `_type` (and `variant`) keep the documents distinct; the alternative
        # was an empty key, which silently defeats the binary search. Revisit if
        # relaton ever treats `prefix + number` alone as an identity.
        DEFAULT_CODE = "C2"

        # Build NESC identifier from parsed hash
        #
        # @param parsed_hash [Hash] Hash from parser
        # @return [Identifiers::Nesc::Base] Appropriate NESC identifier instance
        def build(parsed_hash)
          # Determine identifier type based on parsed attributes
          identifier_class = determine_identifier_class(parsed_hash)

          # The code travels through the base initializer as `code:` so it lands
          # in `code_obj` and the CodeNumber mixin hoists the flat split columns
          # relaton indexes on. Every NESC document is the C2-designated code
          # (or a companion of it), so the year-first forms — which print no
          # code — still key under "C2" rather than leaving `root.number` empty.
          identifier = identifier_class.new(
            code: parsed_hash[:code]&.to_s || DEFAULT_CODE,
          )

          # Set year (required for all NESC identifiers)
          if parsed_hash[:year]
            identifier.year = parsed_hash[:year].to_s
          end

          # Set variant (Handbook, Redline, etc.)
          if parsed_hash[:variant]
            identifier.variant = parsed_hash[:variant].to_s
          end

          # Set edition (for handbooks)
          if parsed_hash[:edition]
            identifier.edition = parsed_hash[:edition].to_s
          end

          # Set month (for drafts)
          if parsed_hash[:month]
            identifier.month = parsed_hash[:month].to_s
          end

          # Registered-trademark "(R)" marks and the "(NESC(R))" abbreviation
          # suffix (year-first forms) — see Identifiers::Nesc::Base#name_portion.
          identifier.registered = true if parsed_hash[:name_registered] ||
            parsed_hash[:abbr_registered]
          if parsed_hash[:paren_abbr]
            identifier.abbr_suffix = true
            identifier.abbr_suffix_registered = true if parsed_hash[:paren_registered]
          end

          identifier
        end

        private

        # Determine the appropriate identifier class
        #
        # @param parsed_hash [Hash] Parsed attributes
        # @return [Class] Identifier class to instantiate
        def determine_identifier_class(parsed_hash)
          # Draft identifiers
          return Identifiers::Nesc::Draft if parsed_hash[:draft]

          # Variant-based identifiers
          if parsed_hash[:variant]
            case parsed_hash[:variant].to_s
            when "Handbook"
              return Identifiers::Nesc::Handbook
            when "Redline"
              return Identifiers::Nesc::Redline
            end
          end

          # C2 code means standard NESC
          return Identifiers::Nesc::Standard if parsed_hash[:code]

          # Plain year-first edition. Never the abstract Nesc::Base — only
          # concrete leaves carry the CodeNumber `number` column.
          Identifiers::Nesc::Edition
        end
      end
    end
  end
end
