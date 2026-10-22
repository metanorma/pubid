# frozen_string_literal: true

module Pubid
  module Nist
    module Series
      # Default series behavior. All hooks return the "generic" answer so a
      # series bug can be fixed by overriding the relevant hook in a subclass.
      class Base
        # Whether an uppercase letter at the end of `first_number` stays in the
        # number (true) or is extracted as a separate Part component (false).
        def self.preserve_letter_suffix?(parsed_hash)
          parsed_hash[:parsed_format] == :mr
        end

        # Cast a `:letter_number` parser hash (e.g., from "800-56A").
        # Return a cast hash, or nil to skip assignment.
        # Default: split letter suffix into a Part component.
        def self.cast_letter_number(value, _parsed_hash)
          # The n+UPPERCASE annex capture (pubid#555, e.g., 800-85nB) arrives
          # as a nested letter_suffix_extra: it casts to the n-notation Part
          # (Part.new(type: "n", value: "B") renders "nB").
          if value[:letter_suffix].is_a?(Hash)
            letter = value[:letter_suffix][:letter_suffix_extra].to_s
            return nil if letter.empty?

            return { part: Components::Part.new(type: "n", value: letter.upcase) }
          end

          full = combine_letter_suffix(value)
          return nil if full.nil? || full.empty?

          { part: Components::Part.new(type: "", value: full.upcase) }
        end

        # Whether the edition-year cast should use modern (numeric) date format
        # instead of preserving historical month names. FIPS uses modern.
        def self.modern_edition_date?
          false
        end

        # Whether `part_num` alongside `second_num` becomes a Part component
        # (true) or is folded into the compound number (false). IR uses Part.
        def self.part_num_as_component?
          false
        end

        # Hook: build compound number when `letter_num` is present.
        # Return true if the series handled it; false to fall back to default.
        def self.handle_letter_num_compound?(_identifier,
                                              first_num:, letter_base:,
                                              letter_suffix:)
          false
        end

        # Hook: post-process the identifier after compound number is assigned.
        # Override to reverse series-specific preprocessing side effects.
        def self.finalize_identifier(_identifier, _parsed_hash); end

        # Combine `:letter_suffix` and `:letter_suffix_extra` (e.g., "U" + "r").
        # The n+UPPERCASE annex capture nests the extra inside the suffix hash
        # (pubid#555): unwrap it before stringifying.
        def self.combine_letter_suffix(value)
          suffix = value[:letter_suffix]
          suffix = suffix[:letter_suffix_extra] if suffix.is_a?(Hash)
          suffix = suffix.to_s.strip
          extra = value[:letter_suffix_extra].to_s.strip
          extra.empty? ? suffix : "#{suffix}#{extra}"
        end
      end
    end
  end
end
