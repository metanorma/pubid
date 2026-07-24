# frozen_string_literal: true

module Pubid
  module Nist
    # Builder class for constructing NIST identifier objects from parsed data
    # Single Responsibility: Orchestrate parsing pipeline (pre-processing -> routing -> casting -> construction)
    #
    # CRITICAL ARCHITECTURE PRINCIPLE:
    # Builder NEVER makes business logic decisions.
    # Builder ONLY casts parsed data to domain objects.
    #
    # Delegates:
    # - Router: series-to-class mapping (which identifier class to instantiate)
    # - Caster: type coercion (parsed values -> domain component objects)
    class Builder < Pubid::Builder::Base
      def initialize
        @router = Router.new
        @caster = Caster.new
        @normalizer = ParserOutputNormalizer.new
        @circular_supplement_builder = CircularSupplementBuilder.new(self)
      end

      # Build an identifier object from parsed data
      # @param parsed [Hash, Array] the parsed identifier data
      # @return [Identifier] the constructed identifier object
      def build(parsed)
        # Parslet can return array of hashes - merge them
        parsed_hash = parsed.is_a?(Array) ? flatten_array(parsed) : parsed

        # Pure in-place shape corrections: parser-output normalization that
        # only mutates parsed_hash. Extraction logic that needs to surface
        # components to the construction phase stays below.
        @normalizer.normalize(parsed_hash)

        # NEW: Fix for letter suffix in number with edition_dash_year
        # Pattern: "304a-2017" where parser returns first_number="304a" and edition_dash_year="2017"
        # Expected: number="304", part="A", edition with type="e" and id="2017"
        # We'll handle this by extracting the info and NOT adding :part to parsed_hash
        # to avoid it being processed by cast(:part, ...) which would set type="pt"
        letter_suffix_part = nil
        edition_from_dash_year = nil
        if parsed_hash[:first_number]&.to_s&.match?(/^[0-9]+[a-zA-Z]$/) && parsed_hash[:edition_dash_year]
          number_str = parsed_hash[:first_number].to_s
          # Extract letter suffix from number
          if match_data = number_str.match(/^([0-9]+)([a-zA-Z])$/)
            base_number = match_data[1]
            letter_suffix = match_data[2].upcase

            # Update first_number to exclude letter suffix
            parsed_hash[:first_number] =
              Components::Code.new(value: base_number)

            # Store Part component for later (after identifier is initialized)
            letter_suffix_part = Components::Part.new(type: "",
                                                      value: letter_suffix)

            # Convert edition_dash_year to Edition component with type="e"
            dash_year = parsed_hash[:edition_dash_year][:dash_year]
            edition_from_dash_year = Components::Edition.new(type: "e",
                                                             id: dash_year)
            parsed_hash.delete(:edition_dash_year) # Remove the old key
          end
        end

        # NEW: Fix for edition embedded in second_number
        # Pattern: "53e5" where second_number="53e5" with edition "e5" embedded
        # Expected: second_number="53", edition with type="e" and id="5"
        if parsed_hash[:second_number]&.to_s&.match?(/^\d+[a-zA-Z]\d+$/)
          second_str = parsed_hash[:second_number].to_s
          # Extract edition from second_number (e.g., "53e5" -> "53" + edition "e5")
          if match_data = second_str.match(/^(\d+)([a-zA-Z])(\d+)$/)
            base_number = match_data[1]
            edition_letter = match_data[2]
            edition_id = match_data[3]

            # Update second_number and create Edition component
            parsed_hash[:second_number] =
              Components::Code.new(value: base_number)
            # Store Edition component for later (after identifier is initialized)
            edition_from_embedded = Components::Edition.new(
              type: edition_letter, id: edition_id,
            )
          end
        end

        # NEW: Check for CIRC supplement pattern
        # Note: :base_portion is lost during parser merge, so check for supplement indicators
        if parsed_hash[:supplement_date_range] || parsed_hash[:supplement_slash_year] ||
            parsed_hash[:supplement_month_year] || parsed_hash[:supplement_year] ||
            parsed_hash[:supplement] || parsed_hash[:base_portion]
          return build_circular_supplement(parsed_hash)
        end

        # Locate the appropriate identifier class via Router
        identifier = @router.locate_identifier_klass(parsed_hash).new

        # Resolve the series policy once — every series-specific decision
        # flows through this object instead of branching on the parsed shape.
        series = Series.for(parsed_hash)

        # NEW: If we extracted a letter suffix Part, assign it now (after identifier initialization)
        if letter_suffix_part
          identifier.part = letter_suffix_part
        end

        # NEW: If we extracted an Edition from edition_dash_year, assign it now
        if edition_from_dash_year
          identifier.edition = edition_from_dash_year
        end

        # NEW: If we extracted an Edition from embedded second_number, assign it now
        if edition_from_embedded
          identifier.edition = edition_from_embedded
        end

        # NEW: If we extracted an Edition from edition_dash_year with embedded edition in first_number, assign it now
        if parsed_hash[:edition_embedded_with_year]
          identifier.edition = parsed_hash[:edition_embedded_with_year]
        end

        # NEW: If we extracted an Edition from edition_dash_year as year-only edition, assign it now
        if parsed_hash[:edition_from_year]
          identifier.edition = parsed_hash[:edition_from_year]
        end

        # NEW: If we extracted an Edition from edition_dash_year with embedded edition, assign it now
        if parsed_hash[:edition_with_year]
          identifier.edition = parsed_hash[:edition_with_year]
        end

        # NEW: If we have a direct Edition from parsed_hash, assign it now
        # (Used for IR patterns where large dash_year is treated as edition)
        if parsed_hash[:edition]
          identifier.edition = parsed_hash[:edition]
        end

        # Track first_number, second_number, decimal_number, and letter_number for building compound number
        first_num = nil
        second_num = nil
        decimal_num = nil
        letter_num = nil
        part_num = nil
        extracted_revision = nil

        # Accumulate supplement signals from the casts (a flat value string,
        # the has_revision flag, and date-range start/end) and fold them into a
        # single Components::Supplement at the end. They are intercepted (not
        # assigned) because :supplement is now a component attribute, so a raw
        # string must never be written to it directly.
        supp = { value: nil, has_revision: false, range_start: nil,
                 range_end: nil, present: false }
        capture_supplement = lambda do |k, v|
          case k
          when :supplement then supp[:value] = v
          when :supplement_has_revision then supp[:has_revision] = !!v
          when :supplement_date_range_start then supp[:range_start] = v
          when :supplement_date_range_end then supp[:range_end] = v
          else return false
          end
          supp[:present] = true
          true
        end

        # Cast and assign all attributes
        parsed_hash.each_pair do |key, value|
          realized_components = @caster.cast(key.to_sym, value, parsed_hash) # Pass parsed_hash for context
          next if realized_components.nil?
          next if !realized_components.is_a?(Hash) && capture_supplement.call(
            key.to_sym, realized_components
          )

          # Track number components
          if key == :first_number && realized_components.is_a?(Components::Code)
            first_num = realized_components
          elsif key == :second_number && realized_components.is_a?(Components::Code)
            second_num = realized_components
          elsif key == :crpl_range && realized_components.is_a?(Components::Code)
            # crpl_range is treated as second_number for compound number construction
            second_num = realized_components
          elsif key == :part_number
            part_num = value.to_s
          # NEW: Track decimal_number for IR identifiers (e.g., 80-2073.3)
          # decimal_number is stored as hash with :decimal_base and :decimal_suffix
          elsif key == :decimal_number && realized_components.is_a?(Hash)
            # Store the raw hash for processing during compound number construction
            decimal_num = realized_components
          # NEW: Track letter_number for NCSTAR identifiers (e.g., 1-1A, 1-3B)
          # letter_number is stored as hash with :letter_base and :letter_suffix
          # For SpecialPublication (e.g., 800-56A), we need to:
          # 1. Store the original hash for compound number construction (letter_base)
          # 2. Create a Part component from letter_suffix
          elsif key == :letter_number
            # Store the original hash for compound number construction
            letter_num = value
            # If cast returned a hash with a part component, it will be assigned below
          end

          # Handle composite hash returns (multiple related values)
          case realized_components
          when Hash
            realized_components.each_pair do |sub_key, sub_value|
              # Track first_number from hash returns
              if sub_key == :first_number && sub_value.is_a?(Components::Code)
                first_num = sub_value
              # Track second_number from hash returns
              elsif sub_key == :second_number && sub_value.is_a?(Components::Code)
                second_num = sub_value
              # NEW: Handle second_number with edition (hash with :number_only and :edition_id)
              # For "126r2013": parser returns {:number_only=>"126", :edition_id=>"2013"}
              # We DON'T convert to Components::Code here; we process it during compound number construction
              elsif sub_key == :second_number && sub_value.is_a?(Hash)
                if sub_value[:number_only] && sub_value[:edition_id]
                  # Store the raw hash for processing during compound number construction
                  # This prevents the hash from being assigned directly to identifier.number
                  second_num = sub_value
                  extracted_revision = "r" # Mark as revision format
                end
              # Track revision extraction
              elsif sub_key == :revision
                extracted_revision = sub_value
              end
              # Skip assignment for second_number hashes - they'll be processed during compound number construction
              next if sub_key == :second_number && sub_value.is_a?(Hash) && sub_value[:number_only]

              # Intercept supplement signals into the accumulator instead of
              # assigning them (supplement is now a component built at the end).
              next if capture_supplement.call(sub_key, sub_value)

              attrs = identifier.class.attributes
              setter = "#{sub_key}="
              if attrs.key?(sub_key.to_sym)
                identifier.public_send(setter,
                                       sub_value)
              end
            end
          else
            attrs = identifier.class.attributes
            setter = "#{key}="
            if attrs.key?(key.to_sym)
              identifier.public_send(setter,
                                     realized_components)
            end
          end
        end

        # Build compound number from first_number and second_number
        if first_num && !identifier.number
          # Skip if this is a v#n# pattern - now handled as Part component
          if identifier.volume && identifier.issue_number
          # V#n# pattern handled as Part in first_number cast
          # NEW: Handle decimal number pattern (e.g., 80-2073.3 for IR identifiers)
          # decimal_num is {:decimal_base => "2073", :decimal_suffix => "3"}
          elsif decimal_num
            decimal_base = decimal_num[:decimal_base].to_s
            decimal_suffix = decimal_num[:decimal_suffix].to_s
            identifier.number = Components::Code.new(value: "#{first_num.value}-#{decimal_base}.#{decimal_suffix}")
          # NEW: Handle letter number pattern (e.g., 1-1A, 1-3B for NCSTAR identifiers)
          # letter_num is {:letter_base => "1", :letter_suffix => "A"}
          # Also handles IR series "R" suffix: "79-1786R" -> "79-1786r1"
          elsif letter_num
            letter_base = letter_num[:letter_base].to_s
            letter_suffix = letter_num[:letter_suffix].to_s

            if series.handle_letter_num_compound?(identifier,
                                                   first_num: first_num,
                                                   letter_base: letter_base,
                                                   letter_suffix: letter_suffix)
              # Series-specific handler took ownership (e.g., IR "R" → r1)
            elsif identifier.part
              # SpecialPublication pattern: letter_suffix is separate Part component
              identifier.number = Components::Code.new(value: "#{first_num.value}-#{letter_base}")
            else
              # NCSTAR pattern: letter_suffix is part of the number
              identifier.number = Components::Code.new(value: "#{first_num.value}-#{letter_base}#{letter_suffix}")
            end
          elsif second_num
            # Check for special patterns first
            # NEW: Handle second_number with edition (hash from parser pattern)
            # For "126r2013": second_num is {:number_only=>"126", :edition_id=>"2013"}
            if second_num.is_a?(Hash) && second_num[:number_only] && second_num[:edition_id]
              # Extract components from hash
              number_part = second_num[:number_only].to_s
              edition_id = second_num[:edition_id].to_s

              # Create Edition component
              edition_obj = Components::Edition.new(type: "r", id: edition_id)

              identifier.number = Components::Code.new(value: "#{first_num.value}-#{number_part}")
              identifier.edition = edition_obj
              identifier.edition_component = edition_obj
              identifier.revision = "r#{edition_id}"
            # CS Emergency pattern: e104-43 -> number=104, edition_year=1943
            # Logic: e104-43 means "emergency 104 from 1943" (43 = 1943)
            elsif first_num.value.to_s.match?(/^e(\d{3})$/) &&
                second_num.value.to_s.match?(/^\d{2}$/)
              match_data = first_num.value.to_s.match(/^e(\d{3})$/)
              number_part = match_data[1] # 104
              year_suffix = second_num.value.to_s # 43
              # Edition year: 19 + 43 = 1943 (1900s + year suffix)
              edition_year = "19#{year_suffix}"

              # Create Edition component
              edition_obj = Components::Edition.new(type: "e", id: edition_year)

              identifier.number = Components::Code.new(value: number_part)
              identifier.edition = edition_obj
              identifier.edition_component = edition_obj
            elsif first_num.value.to_s.match?(/^(\d+)e(\d+)$/) &&
                second_num.value.to_s.match?(/^\d{2,4}$/)
              # Pattern: "11e2-1915" OR "123e2-50" parsed as first="11e2"|"123e2", second="1915"|"50"
              # Extract number and edition from first_num
              match_data = first_num.value.to_s.match(/^(\d+)e(\d+)$/)
              number_part = match_data[1]
              edition_id = match_data[2]
              year_part = second_num.value.to_s

              # Expand 2-digit year to 4-digit (50 -> 1950)
              year_part = "19#{year_part}" if year_part.length == 2

              identifier.number = Components::Code.new(value: number_part)

              # For edition+year patterns, handling depends on identifier type:
              # - CIRC: edition number + year as additional_text, rendered with dot ("11e2-1915" -> "11e2.1915")
              # - HB, others: edition number + year as additional_text, rendered with dash ("44e2-1955")
              # Both use the same Edition component structure, only rendering differs
              edition_obj = Components::Edition.new(type: "e",
                                                    id: edition_id, additional_text: year_part)
              identifier.edition = edition_obj
              identifier.edition_component = edition_obj
            elsif first_num.value.to_s.match?(/^(\d+)supp?$/) &&
                second_num.value.to_s.match?(/^\d{4}$/)
              # Pattern: "25supp-1924" parsed as first="25supp", second="1924"
              number_part = first_num.value.to_s.match(/^(\d+)supp?$/)[1]
              year_part = second_num.value.to_s

              identifier.number = Components::Code.new(value: number_part)
              supp[:value] = year_part
              supp[:present] = true
            elsif second_num.value.to_s.match?(/^(\d+)supp?$/)
              # Pattern: "800-53sup"/"800-53supp" - bare marker on the compound
              # second number. Strip it and isolate as supplement="" (single-p).
              second_part = second_num.value.to_s.match(/^(\d+)supp?$/)[1]
              compound = "#{first_num.value}-#{second_part}"
              identifier.number = Components::Code.new(value: compound)
              supp[:value] = ""
              supp[:present] = true
            elsif identifier.is_a?(Identifiers::TechnicalNote) &&
                second_num.value.to_s.match?(/^(19|20)\d{2}$/)
              # SPECIAL CASE FOR TN: second_num is edition year
              # Following "date IS edition" rule: -1993 becomes Edition(type: "e", id: "1993")
              identifier.number = first_num
              edition_obj = Components::Edition.new(type: "e",
                                                    id: second_num.value.to_s)
              identifier.edition_component = edition_obj
              identifier.edition = edition_obj
              identifier.edition_year = second_num.value.to_s
            elsif part_num && series.part_num_as_component?
              # IR pattern: part_num becomes a Part component (type="pt"),
              # not folded into the compound number.
              identifier.part = Components::Part.new(type: "pt",
                                                     value: part_num)
              identifier.number = Components::Code.new(value: "#{first_num.value}-#{second_num.value}")
            else
              # For GCR and others, include part number in compound number
              compound_value = "#{first_num.value}-#{second_num.value}"
              compound_value += "-#{part_num}" if part_num
              identifier.number = Components::Code.new(value: compound_value)
            end
          else
            # No second_num, use first_num directly
            identifier.number = first_num
          end
        end

        # Apply extracted revision if not already set
        if extracted_revision && !identifier.edition
          # Convert extracted revision to Edition component
          identifier.edition = Components::Edition.new(type: "r",
                                                       id: extracted_revision.to_s)
        end

        # Series-specific post-processing (e.g., IR reverses the "84e2946"
        # form that preprocessing produced back to "84-2946").
        series.finalize_identifier(identifier, parsed_hash)

        # publisher_was_parsed defaults to true (see Identifier), so only
        # the prefix-less case needs recording: assign false when no publisher
        # was parsed/extracted, and leave it unset (default true, omitted from
        # to_hash) when one was. Keeps the common publisher-bearing id lean.
        identifier.publisher_was_parsed = false unless identifier.publisher

        # NEW: Convert revision with month+year to update component (V1 compatibility)
        # Patterns like "NIST IR 4743rJun1992" should be rendered as "NIST IR 4743/Upd1-199206"
        if parsed_hash[:revision_month] && parsed_hash[:revision_year]
          # rJun1992 pattern: revision_month is "Jun", revision_year is "1992"
          month_str = parsed_hash[:revision_month].to_s
          year_str = parsed_hash[:revision_year].to_s

          # Convert month name to number (Jun -> 06, Nov -> 11, etc.)
          month_num = @caster.month_name_to_number(month_str)

          # Create update component with default number=1, converted year and month
          update_obj = Components::Update.new(
            number: "1",
            year: year_str,
            month: sprintf("%02d", month_num),
            prefix: "slash", # V1 uses /Upd format
          )

          # Set both V2 component and legacy attribute for backward compatibility
          identifier.update_component = update_obj
          identifier.update = update_obj

          # Clear the legacy revision_year/revision_month attributes
          identifier.revision_year = nil
          identifier.revision_month = nil
        end

        # Fold the accumulated supplement signals into the single structured
        # supplement component (the source of truth).
        if (supp[:present] || supp[:has_revision]) &&
            identifier.class.attributes.key?(:supplement)
          identifier.supplement = supplement_from(
            value: supp[:value], has_revision: supp[:has_revision],
            range_start: supp[:range_start], range_end: supp[:range_end]
          )
        end

        identifier
      end

      # Build a Components::Supplement from the builder's accumulated raw signals
      # (flat value string, has_revision flag, fused date-range start/end). This
      # is the one place raw supplement text becomes the structured component.
      def supplement_from(value:, has_revision:, range_start:, range_end:)
        if range_start || range_end
          component = Components::Supplement.new
          # Split the fused "Jun1925"/"Jun1926" strings into isolated start/end
          # month+year nodes (start reuses :month/:year, end uses *_end).
          # Each end is either a fused "Jun1925" (month+year) or a bare "1925"
          # (year-only range, no month).
          if range_start && (m = range_start.match(/\A([A-Za-z]{3,9})?(\d{4})\z/))
            component.month = m[1]
            component.year = m[2]
          end
          if range_end && (m = range_end.match(/\A([A-Za-z]{3,9})?(\d{4})\z/))
            component.month_end = m[1]
            component.year_end = m[2]
          end
          component
        else
          Components::Supplement.from_raw(value, has_revision: has_revision)
        end
      end

      # Delegate CIRC/LCIRC supplement construction to the dedicated builder.
      # See CircularSupplementBuilder for the construction pipeline.
      def build_circular_supplement(parsed_hash)
        @circular_supplement_builder.build_circular_supplement(parsed_hash)
      end
    end
  end
end
