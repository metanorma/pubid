# frozen_string_literal: true

module Pubid
  module Nist
    # Builder dedicated to CIRC/LCIRC supplement identifier construction.
    #
    # Extracted from Builder.build_circular_supplement* methods to keep the
    # main Builder focused on orchestration. The circular supplement
    # construction pipeline is a self-contained sub-flow that:
    #
    # 1. Decides between the wrapper class (CircularSupplement) for V1-compat
    #    update forms (slash-year "118supp3/1926" -> ".../Upd1-192603";
    #    implicit revision "145r11/1925") and the normal Circular /
    #    LetterCircular classes for everything else.
    # 2. Builds the base identifier recursively via Builder#build.
    # 3. Attaches the supplement as either an isolated component on the normal
    #    class, or a structured edition/update on the wrapper.
    #
    # Single Responsibility: Construct CIRC/LCIRC supplement identifier
    # objects from parsed data, calling back to the parent Builder for base
    # identifier construction.
    class CircularSupplementBuilder
      # @param builder [Builder] the parent builder (for recursive base build)
      def initialize(builder)
        @builder = builder
      end

      # Build CircularSupplement with base wrapping
      # @param parsed_hash [Hash] the parsed supplement data
      # Build a CIRC/LCIRC supplement. Most forms collapse onto the base
      # identifier's normal class (Circular / LetterCircular) with isolated
      # supplement attributes, so they share one model with every other series
      # and are queryable by part. The V1-compat update forms (slash-year
      # "118supp3/1926" -> ".../Upd1-192603"; implicit revision "145r11/1925")
      # render through an Update component the flat supplement model can't
      # express, so they stay on the CircularSupplement wrapper for now.
      def build_circular_supplement(parsed_hash)
        if parsed_hash[:supplement_slash_year].is_a?(Hash) ||
            parsed_hash[:implicit_supplement].is_a?(Hash)
          return build_circular_supplement_wrapper(parsed_hash)
        end

        series_value = if parsed_hash[:circ_series].is_a?(Hash)
                         parsed_hash[:circ_series][:series]
                       else
                         parsed_hash[:series]
                       end

        # Date-range supplement (no base document): a plain base identifier with
        # no number, carrying the range. parsed_format is left at the default so
        # a dotted MR input still normalizes to the spaced short form.
        if parsed_hash[:supplement_date_range].is_a?(Hash)
          range = parsed_hash[:supplement_date_range]
          identifier = @builder.build({ series: series_value })
          ms = range[:supp_month_start]&.to_s
          ys = range[:supp_year_start]&.to_s
          me = range[:supp_month_end]&.to_s
          ye = range[:supp_year_end]&.to_s
          # Month is optional: a year-only range ("sup1925-1926") passes just the
          # bare year, which supplement_from parses into year/year_end.
          identifier.supplement = @builder.supplement_from(
            value: nil, has_revision: false,
            range_start: (ys ? "#{ms}#{ys}" : nil),
            range_end: (ye ? "#{me}#{ye}" : nil)
          )
          return identifier
        end

        # Based supplement: build the base, then attach the supplement as an
        # isolated component on that normal class.
        identifier = build_circular_supplement_base(parsed_hash, series_value)
        raw = if parsed_hash[:supplement_month_year]
                parsed_hash[:supplement_month_year].to_s
              elsif parsed_hash[:supplement_year]
                parsed_hash[:supplement_year].to_s
              else
                "" # supplement_empty or bare marker
              end
        identifier.supplement = Components::Supplement.from_raw(raw)
        identifier
      end

      # Build just the base identifier for a based CIRC/LCIRC supplement, from
      # base_portion (number, optional edition "101e2" or letter suffix "378G")
      # or the merged first_number fallback. Returns the normal class.
      def build_circular_supplement_base(parsed_hash, series_value)
        base_portion = parsed_hash[:base_portion]
        unless base_portion
          return @builder.build({
                                  publisher: parsed_hash[:publisher],
                                  series: series_value || parsed_hash[:series],
                                  first_number: parsed_hash[:first_number],
                                  parsed_format: parsed_hash[:parsed_format],
                                })
        end

        base_number = if base_portion.is_a?(Hash)
                        base_portion[:simple_number] || base_portion[:base_number]
                      else
                        base_portion
                      end

        letter_suffix = nil
        if base_portion.is_a?(Hash) && base_portion[:letter_suffix]
          letter_suffix = base_portion[:letter_suffix].to_s.upcase
        end

        publisher_value = nil
        if parsed_hash[:circ_series].is_a?(Hash) && parsed_hash[:circ_series][:series]
          series_str = parsed_hash[:circ_series][:series].to_s
          publisher_value = series_str.split.first if series_str.include?(" ")
        end

        has_edition = base_portion.is_a?(Hash) && base_portion[:edition_number]

        base_number_with_suffix = base_number.to_s
        base_number_with_suffix += letter_suffix if letter_suffix
        if has_edition
          base_number_with_suffix += "e#{base_portion[:edition_number]}"
        end

        base_hash = {
          series: series_value,
          first_number: base_number_with_suffix,
          parsed_format: parsed_hash[:parsed_format],
        }
        base_hash[:publisher] = publisher_value if publisher_value
        base_hash[:edition_e] =
          { edition_id: base_portion[:edition_number] } if has_edition

        @builder.build(base_hash)
      end

      # @return [Identifiers::CircularSupplement] the supplement identifier
      def build_circular_supplement_wrapper(parsed_hash)
        supplement = Identifiers::CircularSupplement.new

        # Extract series from circ_series if present (nested structure from parser)
        series_value = nil
        if parsed_hash[:circ_series].is_a?(Hash)
          series_value = parsed_hash[:circ_series][:series]
        elsif parsed_hash[:series]
          series_value = parsed_hash[:series]
        end

        # Handle date range supplement (no base)
        if parsed_hash[:supplement_date_range].is_a?(Hash)
          range = parsed_hash[:supplement_date_range]
          month_start = range[:supp_month_start]&.to_s
          year_start = range[:supp_year_start]&.to_s
          month_end = range[:supp_month_end]&.to_s
          year_end = range[:supp_year_end]&.to_s

          supplement.supplement_date_range_start = "#{month_start}#{year_start}" if month_start && year_start
          supplement.supplement_date_range_end = "#{month_end}#{year_end}" if month_end && year_end

          return supplement
        end

        # Build base identifier from base_portion (if present)
        # If not present (because it was merged during parsing), use first_number
        if parsed_hash[:base_portion]
          # Extract the actual number value from base_portion hash
          # base_portion can be: {:simple_number=>"118"}, {:base_number=>"145", :revision_letter=>"r", :revision_number=>"11"}, etc.
          base_portion = parsed_hash[:base_portion]
          base_number = if base_portion.is_a?(Hash)
                          # Extract the value from whichever key is present
                          base_portion[:simple_number] || base_portion[:base_number]
                        else
                          base_portion
                        end

          # Check for letter suffix in base_portion (e.g., "378G")
          letter_suffix = nil
          if base_portion.is_a?(Hash) && base_portion[:letter_suffix]
            letter_suffix = base_portion[:letter_suffix].to_s.upcase
          end

          # Extract publisher from circ_series if present
          publisher_value = nil
          if parsed_hash[:circ_series].is_a?(Hash) && parsed_hash[:circ_series][:series]
            series_str = parsed_hash[:circ_series][:series].to_s
            # Extract publisher from series (e.g., "NBS LCIRC" -> "NBS")
            publisher_value = series_str.split.first if series_str.include?(" ")
          end

          # Check if base_portion has revision (for patterns like "145r11/1925")
          has_revision = base_portion.is_a?(Hash) && base_portion[:revision_letter] && base_portion[:revision_number]

          # NEW: Check if base_portion has edition_number (for patterns like "101e2")
          has_edition = base_portion.is_a?(Hash) && base_portion[:edition_number]

          # Include letter suffix in base_number if present
          # Also include edition_number if present (for "101e2" pattern)
          base_number_with_suffix = base_number.to_s
          if letter_suffix
            base_number_with_suffix += letter_suffix
          end
          if has_edition
            base_number_with_suffix += "e#{base_portion[:edition_number]}"
          end

          # Reconstruct parse hash for base identifier
          base_hash = {
            series: series_value,
            first_number: base_number_with_suffix,
            parsed_format: parsed_hash[:parsed_format],
          }
          base_hash[:publisher] = publisher_value if publisher_value

          # NEW: Add edition_number to base_hash for patterns like "101e2"
          # This will be processed by the normal build() logic to create Edition component
          if has_edition
            # Create edition_e hash that will be converted to Edition with type="e"
            base_hash[:edition_e] =
              { edition_id: base_portion[:edition_number] }
          end

          # Recursively build base identifier
          # This will go through normal build() process which extracts edition from "101e2"
          supplement.base = @builder.build(base_hash)

          # NEW: Handle revision + implicit supplement pattern (e.g., "145r11/1925")
          # Create update format: "Upd1-{year}{revision_number}"
          if has_revision && parsed_hash[:implicit_supplement].is_a?(Hash)
            revision_number = base_portion[:revision_number].to_s
            supplement_year = parsed_hash[:implicit_supplement][:implicit_supplement_year].to_s

            # Create Update component for revision+supplement pattern.
            # Renders "/Upd1-{year}{revision_number}" via Update#to_s(:short).
            # The year+revision are fused into the year field (month left nil) so
            # the revision is NOT zero-padded (e.g. "145r6/1925" -> "Upd1-19256",
            # not "192506"). Must be a Components::Update (not a String) so
            # :update serializes.
            supplement.update = Components::Update.new(
              number: "1", year: "#{supplement_year}#{revision_number}",
              prefix: "slash"
            )
            supplement.implicit_supplement = true # Mark as implicit supplement for rendering
          end
        elsif parsed_hash[:first_number]
          # base_portion was lost during merge, use first_number to build base identifier
          base_hash = {
            publisher: parsed_hash[:publisher],
            series: series_value || parsed_hash[:series],
            first_number: parsed_hash[:first_number],
            parsed_format: parsed_hash[:parsed_format],
          }

          # Recursively build base identifier
          supplement.base = @builder.build(base_hash)
        end

        # Build supplement edition from captured data
        if parsed_hash[:supplement_month_year]
          # Parse month+year format like "Jan1924"
          month_year = parsed_hash[:supplement_month_year].to_s
          supplement.edition = Components::Edition.new(type: "s",
                                                       id: month_year)
        elsif parsed_hash[:supplement_year]
          # Just year: 1924
          supplement.edition = Components::Edition.new(type: "s",
                                                       id: parsed_hash[:supplement_year].to_s)
        elsif parsed_hash[:supplement_slash_year].is_a?(Hash)
          # NEW: Handle supplement_slash_year pattern (e.g., "sup12/1926", "sup1/1927")
          # V1 format: "Upd1-192612" where "1" is fixed and "192612" is year+number concatenated
          # Single digit numbers are zero-padded: "sup1/1927" -> "Upd1-192701"
          supp_hash = parsed_hash[:supplement_slash_year]
          supp_number = supp_hash[:supp_number]&.to_s
          supp_year = supp_hash[:supp_year]&.to_s

          # Pad supplement number to 2 digits for single-digit numbers
          supp_number_padded = supp_number.rjust(2, "0")

          # Create Update component for supplement (V1 compatibility uses Update for supplements).
          # Renders "/Upd1-{year}{padded_number}" via Update#to_s(:short). The
          # year and already-padded number are fused into the year field (month
          # left nil) so rendering reproduces the V1 string exactly. Must be a
          # Components::Update (not a String) so :update serializes.
          supplement.update = Components::Update.new(
            number: "1", year: "#{supp_year}#{supp_number_padded}",
            prefix: "slash"
          )
        elsif parsed_hash[:supplement_empty]
          # Empty supplement - no edition
          # supplement.edition remains nil
        end

        supplement
      end
    end
  end
end
