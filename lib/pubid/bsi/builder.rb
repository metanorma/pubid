# frozen_string_literal: true

module Pubid
  module Bsi
    class Builder < Pubid::Builder::Base
      # Default typed stage used when an abbreviation lookup yields no match.
      # Empty/unknown abbreviations fall back to the published British Standard.
      DEFAULT_TYPED_STAGE = Pubid::Components::TypedStage.new(
        code: :pubbs,
        stage_code: :published,
        type_code: :bs,
        abbr: ["BS"],
        name: "British Standard",
        harmonized_stages: %w[60.00 60.60],
      ).freeze

      def self.build(parsed_data)
        new.build(parsed_data)
      end

      def build(data)
        data = flatten_array(data) if data.is_a?(Array)

        # Store original data to check if BSI prefix was present
        @original_data = data.dup

        # Check for StandaloneAmendment first (very specific pattern)
        if data[:standalone_amendment] || data[:parenthesized_amd]
          return build_standalone_amendment(data)
        end

        # Check for CommitteeDocument
        if data[:committee_document]
          return build_committee_document(data[:committee_document])
        end

        # Check for Index identifier first
        if data[:index_identifier]
          return build_index(data[:index_identifier])
        end

        # Check for Supplementary Index identifier
        if data[:supplementary_index_identifier]
          return build_supplementary_index(data[:supplementary_index_identifier])
        end

        # Check for Explanatory Supplement identifier
        if data[:explanatory_supplement_identifier]
          return build_explanatory_supplement(data[:explanatory_supplement_identifier])
        end

        # Check for Method identifier
        if data[:method_identifier]
          return build_method(data[:method_identifier])
        end

        # Check for Test Method identifier
        if data[:test_method_identifier]
          return build_test_method(data[:test_method_identifier])
        end

        # Check for Section identifier
        if data[:section_identifier]
          return build_section(data[:section_identifier])
        end

        # Check for Detailed Specification identifier
        if data[:detailed_specification]
          return build_detailed_specification(data[:detailed_specification])
        end

        # Check for DISC identifier
        if data[:disc_identifier]
          return build_disc(data[:disc_identifier])
        end

        # Check for Aerospace identifier with letter suffix edition
        if data[:aerospace_identifier]
          return build_aerospace_identifier(data[:aerospace_identifier])
        end

        # Check for SupplementDocument first
        if data[:supplement_document]
          return build_supplement_document(data[:supplement_document])
        end

        # Check for AddendumDocument
        if data[:addendum_document]
          return build_addendum_document(data[:addendum_document])
        end

        # Check for BundledIdentifier
        if data[:bundled_parts] || data[:bundled_list]
          return build_bundled_identifier(data)
        end

        # Check for Set identifier
        if data[:set]
          return build_set(data[:set])
        end

        # Extract supplements before processing
        supplements_data = extract_supplements(data)

        # Check for Value-Added Publication wrapper first
        if data[:pdf_format] || data[:tc_format] || data[:book_format]
          return build_value_added_publication(data, supplements_data)
        end

        # Check for National Annex first (most specific)
        # NationalAnnex can have:
        # - Own supplements: "NA+A1:2012 to BASE"
        # - Adopted string: "NA to BS EN 1234"
        if data[:na_prefix]
          return build_national_annex(data, supplements_data)
        elsif data[:adopted_string]
          # Adopted identifiers carry their supplements and Expert-commentary
          # suffix *inside* the adopted string, so build_adopted_identifier does
          # all the wrapping. Wrapping again here would double-wrap (a second
          # ExpertCommentary around the first) and break #base_document.
          return build_adopted_identifier(data)
        end

        # Determine identifier class using the module's lookup helpers
        identifier = locate_identifier_klass(data).new
        assign_attributes(identifier, data)

        # Wrap with consolidated if supplements present
        if supplements_data.any?
          identifier = wrap_with_consolidated(identifier,
                                              supplements_data)
        end

        # Wrap with ExpertCommentary if needed (full "Expert Commentary" form
        # arrives as the standalone :expert_commentary_full token)
        if data[:expert_commentary] || data[:expert_commentary_full]
          identifier = wrap_with_expert_commentary(identifier)
        end

        identifier
      end

      private

      def build_index(data)
        # Extract values from the parsed data
        data[:publisher]&.to_s
        number_val = data[:number][:number] if data[:number].is_a?(Hash)
        number_val ||= data[:number].to_s if data[:number]
        year_val = data[:year].to_i if data[:year]

        # Extract index_suffix information
        index_suffix_data = data[:index_suffix]
        format = "space" # default
        issue_number = nil

        if index_suffix_data.is_a?(Hash)
          if index_suffix_data[:colon_sep]
            format = "colon"
          elsif index_suffix_data[:issue_number]
            issue_number = index_suffix_data[:issue_number].to_s
          end
        end

        # Build attributes hash (conditional arguments must be handled separately)
        attrs = {
          number: Components::Code.new(value: number_val),
          issue_number: issue_number,
          index_format: format,
        }
        attrs[:date] = Components::Date.new(year: year_val) if year_val

        Identifiers::Index.new(attrs)
      end

      def build_supplementary_index(data)
        # Extract values from the parsed data
        number_val = data[:number][:number] if data[:number].is_a?(Hash)
        number_val ||= data[:number].to_s if data[:number]
        year_val = data[:year].to_i if data[:year]

        # Build attributes hash
        attrs = {
          number: Components::Code.new(value: number_val),
        }
        attrs[:date] = Components::Date.new(year: year_val) if year_val

        Identifiers::SupplementaryIndex.new(attrs)
      end

      def build_explanatory_supplement(data)
        # Extract values from the parsed data
        number_val = data[:number][:number] if data[:number].is_a?(Hash)
        number_val ||= data[:number].to_s if data[:number]
        year_val = data[:year].to_i if data[:year]

        # Extract part from parts array (e.g., [{part: "1"}] -> "1")
        part_val = nil
        if data[:parts].is_a?(Array) && !data[:parts].empty?
          # Parts come as [{part: "1"}], so we need to extract the :part key
          first_part = data[:parts][0]
          if first_part.is_a?(Hash) && first_part[:part]
            part_val = first_part[:part].to_s
          end
        end

        # Build attributes hash
        attrs = {
          number: Components::Code.new(value: number_val),
        }
        attrs[:part] = Components::Code.new(value: part_val) if part_val
        attrs[:date] = Components::Date.new(year: year_val) if year_val

        Identifiers::ExplanatorySupplement.new(attrs)
      end

      def build_method(data)
        # Extract values from the parsed data
        data[:publisher]&.to_s
        number_val = data[:number][:number] if data[:number].is_a?(Hash)
        number_val ||= data[:number].to_s if data[:number]
        year_val = data[:year].to_i if data[:year]

        # Extract part from parts array (e.g., [{part: "1"}] -> "1")
        part_val = nil
        if data[:parts].is_a?(Array) && !data[:parts].empty?
          # Parts come as [{part: "1"}], so we need to extract the :part key
          first_part = data[:parts][0]
          if first_part.is_a?(Hash) && first_part[:part]
            part_val = first_part[:part].to_s
          end
        end

        # Extract method_suffix information
        method_suffix_data = data[:method_suffix]
        method_code = nil
        method_to = nil
        method_and = nil
        is_plural = false

        if method_suffix_data.is_a?(Hash)
          method_code = method_suffix_data[:method_code].to_s if method_suffix_data[:method_code]
          method_to = method_suffix_data[:method_to].to_s if method_suffix_data[:method_to]
          method_and = method_suffix_data[:method_and].to_s if method_suffix_data[:method_and]
          # is_plural is true when we have method_to or method_and
          is_plural = !method_to.nil? || !method_and.nil?
        end

        # Build attributes hash
        attrs = {
          number: Components::Code.new(value: number_val),
          method_code: method_code,
          method_to: method_to,
          method_and: method_and,
          is_plural: is_plural,
        }
        attrs[:part] = Components::Code.new(value: part_val) if part_val
        attrs[:date] = Components::Date.new(year: year_val) if year_val

        Identifiers::Method.new(attrs)
      end

      def build_test_method(data)
        # Extract values from the parsed data
        # Format: BS {number}:{test_series}:{test_id}:{year}
        publisher_val = data[:publisher].to_s if data[:publisher]
        number_val = data[:number][:number] if data[:number].is_a?(Hash)
        number_val ||= data[:number].to_s if data[:number]
        year_val = data[:year].to_i if data[:year]

        # Extract test_method_suffix information
        test_method_suffix_data = data[:test_method_suffix]
        test_series = nil
        test_id = nil

        if test_method_suffix_data.is_a?(Hash)
          test_series = test_method_suffix_data[:test_series].to_s if test_method_suffix_data[:test_series]
          test_id = test_method_suffix_data[:test_id].to_s if test_method_suffix_data[:test_id]
        end

        # Build attributes hash
        attrs = {
          number: Components::Code.new(value: number_val),
          test_series: test_series,
          test_id: test_id,
        }
        if publisher_val
          attrs[:publisher] =
            Components::Publisher.new(body: publisher_val)
        end
        attrs[:date] = Components::Date.new(year: year_val) if year_val

        Identifiers::TestMethod.new(attrs)
      end

      def build_section(data)
        # Extract values from the parsed data
        # Publisher can come from :publisher (BS) or :type (DD, PD, etc.)
        publisher_val = data[:publisher]&.to_s || data[:type]&.to_s
        number_val = data[:number][:number] if data[:number].is_a?(Hash)
        number_val ||= data[:number].to_s if data[:number]
        year_val = data[:year].to_i if data[:year]

        # Extract section_suffix information
        section_suffix_data = data[:section_suffix]
        section_id = nil
        format = "space" # default

        if section_suffix_data.is_a?(Hash)
          section_id = section_suffix_data[:section_id].to_s if section_suffix_data[:section_id]
          format = "colon" if section_suffix_data[:colon_sep]
        end

        # Build attributes hash (conditional arguments must be handled separately)
        attrs = {
          number: Components::Code.new(value: number_val),
          section_id: section_id,
          section_format: format,
        }
        if publisher_val
          attrs[:publisher] =
            Components::Publisher.new(body: publisher_val)
        end
        attrs[:date] = Components::Date.new(year: year_val) if year_val

        Identifiers::Section.new(attrs)
      end

      def build_detailed_specification(data)
        # Extract values from the parsed data
        # Format: "BS {number} N{code}:year" or "BS {number} C{range}:year"
        publisher_val = data[:publisher].to_s if data[:publisher]
        number_val = data[:number][:number] if data[:number].is_a?(Hash)
        number_val ||= data[:number].to_s if data[:number]
        year_val = data[:year].to_i if data[:year]

        # Extract detailed_spec_suffix information
        detailed_spec_data = data[:detailed_spec_suffix]
        spec_code = nil
        if detailed_spec_data.is_a?(Hash) && detailed_spec_data[:spec_code]
          spec_code = detailed_spec_data[:spec_code].to_s
        end

        # Build attributes hash
        attrs = {
          number: Components::Code.new(value: number_val),
        }
        attrs[:spec_code] = Components::Code.new(value: spec_code) if spec_code
        if publisher_val
          attrs[:publisher] =
            Components::Publisher.new(body: publisher_val)
        end
        attrs[:date] = Components::Date.new(year: year_val) if year_val

        Identifiers::DetailedSpecification.new(attrs)
      end

      def build_disc(data)
        # Extract values from the parsed data
        # DISC format: "DISC PD {number}[-{part}]:{year}"
        number_val = data[:number][:number] if data[:number].is_a?(Hash)
        number_val ||= data[:number].to_s if data[:number]
        year_val = data[:year].to_i if data[:year]

        # Extract part from parts array (if present)
        part_val = nil
        if data[:parts]&.any?
          parts_array = Array(data[:parts])
          if parts_array.first && parts_array.first[:part]
            part_val = parts_array.first[:part].to_s
          end
        end

        # Build attributes hash
        attrs = {
          number: Components::Code.new(value: number_val),
        }
        attrs[:part] = Components::Code.new(value: part_val) if part_val
        attrs[:publisher] = Components::Publisher.new(body: "DISC")
        attrs[:date] = Components::Date.new(year: year_val) if year_val

        Identifiers::Disc.new(attrs)
      end

      def build_aerospace_identifier(data)
        # Extract values from the parsed data
        # Format: "BS AU {number}{letter_edition}[-{part}{letter_edition}]:{year}"
        prefix_val = data[:prefix][:prefix] if data[:prefix].is_a?(Hash)
        prefix_val ||= data[:prefix].to_s if data[:prefix]

        # Extract number and letter edition
        number_val = data[:number].to_s if data[:number]

        # Letter edition is a sibling of number in the AST
        edition_val = nil
        if data[:letter_edition].is_a?(Hash)
          edition_val = data[:letter_edition][:letter_edition].to_s
        end

        # Extract part directly (from :part key) or from :part_with_letter_edition
        part_val = nil
        part_edition_val = nil

        # First check for direct :part key (when part_with_letter_edition is used in parser)
        if data[:part]
          if data[:part].is_a?(Hash)
            part_val = data[:part][:part].to_s if data[:part][:part]
            part_edition_val = data[:part][:letter_edition].to_s if data[:part][:letter_edition]
          else
            part_val = data[:part].to_s
          end
        end

        # Also check for :part_with_letter_edition key (for alternative patterns)
        if !part_val && data[:part_with_letter_edition].is_a?(Hash)
          part_val = data[:part_with_letter_edition][:part].to_s if data[:part_with_letter_edition][:part]
          part_edition_val = data[:part_with_letter_edition][:letter_edition].to_s if data[:part_with_letter_edition][:letter_edition]
        end

        # Extract iteration (optional, may be empty)
        iteration_val = nil
        if data[:iteration] && data[:iteration][:iteration] && !data[:iteration][:iteration].empty?
          iteration_val = data[:iteration][:iteration].to_s
        end

        # Extract year
        year_val = data[:year].to_i if data[:year]

        # Use part edition if present, otherwise use number edition
        final_edition = part_edition_val || edition_val

        # Build attributes hash
        attrs = {
          prefix: prefix_val,
          number: Components::Code.new(value: number_val),
        }
        attrs[:part] = Components::Code.new(value: part_val) if part_val
        attrs[:iteration] = iteration_val if iteration_val
        attrs[:edition] = final_edition if final_edition
        attrs[:publisher] = Components::Publisher.new(body: "BS")
        attrs[:date] = Components::Date.new(year: year_val) if year_val

        Identifiers::AerospaceStandard.new(attrs)
      end

      def build_bundled_identifier(data)
        if data[:bundled_parts]
          # Parts/Sections format: "BS 4048:Parts 1 and 2:1966"
          parts_data = data[:bundled_parts]
          base_number = parts_data[:number].to_s
          bundle_type = parts_data[:bundle_type].to_s
          part1 = parts_data[:part1].to_s
          part2 = parts_data[:part2].to_s
          year_val = parts_data[:year].to_i if parts_data[:year]

          # Build base identifier
          base_id = SingleIdentifier.new(
            publisher: Components::Publisher.new(body: "BS"),
            number: Components::Code.new(value: base_number),
          )

          # Build identifiers for each part
          id1 = SingleIdentifier.new(
            publisher: Components::Publisher.new(body: "BS"),
            number: Components::Code.new(value: base_number),
            part: Components::Code.new(value: part1),
          )

          id2 = SingleIdentifier.new(
            publisher: Components::Publisher.new(body: "BS"),
            number: Components::Code.new(value: base_number),
            part: Components::Code.new(value: part2),
          )

          Identifiers::BundledIdentifier.new(
            identifiers: [base_id, id1, id2],
            bundle_type: bundle_type,
            common_year: year_val ? Components::Date.new(year: year_val) : nil,
          )

        elsif data[:bundled_list]
          # List format: "BS SP 10 & 11:1949" or "BS 2SP 68 to BS 2SP 71:1973"
          # bundled_list is an ARRAY of hashes
          list_array = data[:bundled_list]

          # First element has publisher/prefix/bundle_item
          first_elem = list_array[0]
          publisher_val = first_elem[:publisher]&.to_s || "BS"
          prefix_val = first_elem[:prefix]&.to_s

          items = []
          separators = []

          # Process first item
          if first_elem[:bundle_item]
            items << build_bundle_item(first_elem[:bundle_item], publisher_val,
                                       prefix_val)
          end

          # Process remaining elements (may be separator+item or just year)
          list_array[1..].each do |elem|
            if elem[:year]
              # Year element - will be extracted separately
              next
            elsif elem[:bundle_item]
              # This element has separator + bundle_item
              # Preserve separator case for "TO" vs "to"
              sep = if elem[:sep_and]
                      " and "
                    elsif elem[:sep_to]
                      # Check if separator includes uppercase TO
                      to_case = elem[:sep_to][:to_case]&.to_s
                      to_case == "TO" ? " TO " : " to "
                    elsif elem[:sep_ampersand]
                      " & "
                    elsif elem[:sep_semicolon]
                      "; "
                    elsif elem[:sep_comma]
                      ","
                    else
                      " and "
                    end
              separators << sep
              items << build_bundle_item(elem[:bundle_item], publisher_val,
                                         prefix_val)
            end
          end

          # Extract year from last element if present
          year_elem = list_array.find { |e| e[:year] }
          year_val = year_elem[:year].to_i if year_elem

          Identifiers::BundledIdentifier.new(
            identifiers: items,
            separators: separators,
            common_year: year_val ? Components::Date.new(year: year_val) : nil,
          )
        end
      end

      def build_set(data)
        # data is a hash with :set key containing an array of set items
        # The parser returns: {set: [{set_item: {...}}, {set_item: {...}}, ...]}
        # Extract the array from the hash
        items_array = data[:set] || data
        items_array = [items_array] unless items_array.is_a?(Array)

        identifiers = []

        items_array.each_with_index do |item, _i|
          # Extract the actual item data from :set_item key
          item_data = item[:set_item] || item

          # Build string identifier for recursive parsing
          # Note: item_data values are Parslet::Slice objects, need to convert to string
          id_str = ""

          # Publisher (BS)
          if item_data[:publisher]
            id_str += "#{item_data[:publisher]} "
          end

          # Adopted org (ISO, IEC, etc.)
          if item_data[:adopted_org]
            id_str += "#{item_data[:adopted_org]} "
          end

          # Number
          if item_data[:number]
            number_val = if item_data[:number].is_a?(Hash)
                           item_data[:number][:number]&.to_s
                         else
                           item_data[:number].to_s
                         end
            id_str += number_val.to_s if number_val
          end

          # Add part if present (parts is an array from the parser)
          if item_data[:parts].is_a?(Hash) && item_data[:parts][:parts]
            parts_array = item_data[:parts][:parts]
            if parts_array.is_a?(Array) && parts_array.any?
              part_val = parts_array.first[:part]
              id_str += "-#{part_val}"
            end
          end

          # Add year if present
          if item_data[:year]
            id_str += ":#{item_data[:year]}"
          end

          # Skip if empty string
          next if id_str.strip.empty?

          # Recursively parse this identifier
          parsed_id = Pubid::Bsi.parse(id_str)
          identifiers << parsed_id if parsed_id
        end

        Identifiers::Set.new(
          identifiers: identifiers,
          separators: [" + "] * [0, identifiers.length - 1].max,
        )
      end

      def build_bundle_item(item_data, default_publisher, default_prefix)
        # Extract values based on what's present
        if item_data.is_a?(Hash)
          # Check if publisher/prefix were EXPLICITLY present in parse
          has_explicit_publisher = item_data.key?(:publisher)
          has_explicit_prefix = item_data.key?(:prefix)

          publisher_val = item_data[:publisher]&.to_s || default_publisher
          prefix_val = item_data[:prefix]&.to_s || default_prefix
          number_val = if item_data[:number].is_a?(Hash)
                         item_data[:number][:number]&.to_s
                       else
                         item_data[:number]&.to_s
                       end

          # Handle both dash-separated parts and space-separated parts
          parts_val = item_data[:parts]
          space_separated_part_val = item_data[:part]
        else
          # Simple string (alphanumeric like "N001" or just number)
          has_explicit_publisher = false
          has_explicit_prefix = false
          publisher_val = default_publisher
          prefix_val = default_prefix
          number_val = item_data.to_s
          parts_val = nil
          space_separated_part_val = nil
        end

        id = SingleIdentifier.new(
          publisher: Components::Publisher.new(body: publisher_val),
        )
        id.prefix = prefix_val if prefix_val && !prefix_val.empty?
        id.number = Components::Code.new(value: number_val) if number_val

        id.explicit_prefix = has_explicit_publisher || has_explicit_prefix
        id.explicit_publisher = has_explicit_publisher

        # Handle dash-separated parts (from parts array)
        if parts_val.is_a?(Hash) && parts_val[:parts].is_a?(Array)
          parts_array = parts_val[:parts]
          if parts_array.any?
            part_str = parts_array.first[:part].to_s
            id.part = Components::Code.new(value: part_str)
          end
        # Handle space-separated part (direct part attribute)
        elsif space_separated_part_val
          id.part = Components::Code.new(value: space_separated_part_val.to_s)
          # Mark this part as space-separated for rendering
          id.space_separated_part = true
        end

        id
      end

      def wrap_with_expert_commentary(base_id)
        # Determine format from original data
        # Check for expert_commentary_full first (highest priority)
        format = if @original_data[:expert_commentary_full]
                   "full"
                 elsif @original_data[:expert_commentary_topic]
                   "abbr_with_topic"
                 elsif @original_data[:expert_commentary]
                   "abbr"
                 else
                   "abbr" # Default
                 end

        topic = @original_data[:expert_commentary_topic]&.to_s

        Identifiers::ExpertCommentary.new(
          base: base_id,
          format: format,
          topic: topic,
        )
      end

      def build_supplement_document(data)
        # Handle nested hash from parser (when using .as with alternatives)
        data = data[:supplement_document] if data[:supplement_document].is_a?(Hash)

        # Extract values from nested hashes (parser returns {:number => {:number => "1000"}})
        number_val = data[:number][:number] if data[:number].is_a?(Hash)
        iteration_val = data[:iteration][:iteration][0][:iteration] if data[:iteration].is_a?(Hash) && data[:iteration][:iteration].is_a?(Array) && data[:iteration][:iteration].any?
        iteration_val = nil if iteration_val.is_a?(String) && iteration_val.empty?
        parts_val = data[:parts][:parts] if data[:parts].is_a?(Hash)
        flex_prefix_val = data[:flex_prefix].to_s if data[:flex_prefix]

        # Check if this is reverse format: "Supplement No. N (YEAR) to BS NUMBER:YEAR"
        if data[:supplement_number] && data[:supplement_year] && data[:publisher] && number_val && data[:base_year]
          # Reverse format
          reverse_format = true
          base_year = data[:base_year]
        else
          reverse_format = false
          base_year = data[:year]
        end

        # Build base identifier
        base_data = {
          publisher: data[:publisher],
          number: number_val,
          iteration: iteration_val,
          parts: parts_val,
          flex_prefix: flex_prefix_val,
          year: base_year,
        }

        base_id = build(base_data)

        # Determine supplement type (with or without "No.")
        # Check if supp_no_prefix is "No." string or if it's nil/absent
        supplement_type = if data[:supp_no_prefix] == "No."
                            "No."
                          elsif data[:supp_no_prefix]
                            data[:supp_no_prefix].to_s
                          else
                            ""
                          end

        Identifiers::SupplementDocument.new(
          base: base_id,
          supplement_number: data[:supplement_number].to_s,
          supplement_year: data[:supplement_year].to_i,
          supplement_type: supplement_type,
          reverse_format: reverse_format,
          separator: data[:supp_sep].to_s,
        )
      end

      def build_addendum_document(data)
        # Extract values from nested hashes (parser returns {:number => {:number => "1000"}})
        number_val = data[:number][:number] if data[:number].is_a?(Hash)
        iteration_val = data[:iteration][:iteration][0][:iteration] if data[:iteration].is_a?(Hash) && data[:iteration][:iteration].is_a?(Array) && data[:iteration][:iteration].any?
        iteration_val = nil if iteration_val.is_a?(String) && iteration_val.empty?
        parts_val = data[:parts][:parts] if data[:parts].is_a?(Hash)
        flex_prefix_val = data[:flex_prefix].to_s if data[:flex_prefix]

        # Build base identifier
        base_data = {
          publisher: data[:publisher],
          number: number_val,
          iteration: iteration_val,
          parts: parts_val,
          flex_prefix: flex_prefix_val,
          year: data[:base_year],
        }

        base_id = build(base_data)

        # Determine addendum type (with or without "No.")
        addendum_type = if data[:add_no_prefix] == "No."
                          "No."
                        elsif data[:add_no_prefix]
                          data[:add_no_prefix].to_s
                        else
                          ""
                        end

        # Determine separator - use colon when add_sep is nil and base_year is present
        add_sep = data[:add_sep]
        if add_sep.nil? && data[:base_year]
          add_sep = ":"
        elsif add_sep.nil?
          add_sep = ":"
        end

        Identifiers::AddendumDocument.new(
          base: base_id,
          addendum_number: data[:addendum_number].to_s,
          addendum_year: data[:addendum_year].to_i,
          addendum_type: addendum_type,
          separator: add_sep.to_s,
        )
      end

      def build_standalone_amendment(data)
        # Extract from either standalone_amendment or parenthesized_amd key
        amd_data = data[:standalone_amendment] || data[:parenthesized_amd]

        # Handle nested hash if needed
        amd_data = amd_data[:standalone_amendment] || amd_data[:parenthesized_amd] if amd_data.is_a?(Hash) && (amd_data[:standalone_amendment] || amd_data[:parenthesized_amd])

        amendment_number = amd_data[:amendment_number].to_s if amd_data[:amendment_number]
        corrigendum = !amd_data[:corrigendum].nil?
        parenthesized = !data[:parenthesized_amd].nil?

        # NOTE `amd_data[:amendment_number]` above is a PARSE-TREE key and keeps
        # its name; only the attribute moved to `number`.
        attrs = {
          number: Components::Code.new(value: amendment_number),
          corrigendum: corrigendum,
          parenthesized: parenthesized,
        }

        Identifiers::StandaloneAmendment.new(attrs)
      end

      def build_committee_document(data)
        # Extract values from the parsed data
        # Format: "YY/NNNNNNNN DC"
        year_val = data[:year].to_s if data[:year]
        document_number = data[:document_number].to_s if data[:document_number]

        # Convert 2-digit year to 4-digit year (assuming 2000s for 00-99)
        # Could also use a more sophisticated algorithm for year conversion
        full_year = year_val ? "20#{year_val}" : nil

        # NOTE `data[:document_number]` above is a PARSE-TREE key and keeps its
        # name; only the attribute moved to `number`.
        attrs = {
          number: Components::Code.new(value: document_number),
        }
        attrs[:date] = Components::Date.new(year: full_year.to_i) if full_year

        Identifiers::CommitteeDocument.new(attrs)
      end

      def build_value_added_publication(data, _supplements_data)
        # Determine format type
        format = if data[:pdf_format]
                   "PDF"
                 elsif data[:tc_format]
                   "TC"
                 elsif data[:book_format]
                   "BOOK"
                 end

        # Remove VAP format flags from data before building base
        base_data = data.dup
        base_data.delete(:pdf_format)
        base_data.delete(:tc_format)
        base_data.delete(:book_format)

        # Build base identifier (it will handle supplements via supplements_data)
        base_id = build(base_data)

        Identifiers::ValueAddedPublication.new(
          base: base_id,
          format: format,
        )
      end

      def build_national_annex(data, _supplements_data)
        # Build base identifier (what comes after "NA to")
        base_data = data.dup
        base_data.delete(:na_prefix)
        base_data.delete(:na_supplements)
        # DON'T delete base supplements! The base identifier can have its own supplements
        # base_data.delete(:supplements)  # REMOVED - base needs its supplements

        # Recursively parse the base identifier (it will handle its own supplements)
        base_id = build(base_data)

        # Extract NA supplements from the CORRECT path: data[:na_prefix][:na_supplements]
        # Parser nests them under na_prefix, not at top level
        na_supp_raw = if data[:na_prefix].is_a?(Hash) && data[:na_prefix][:na_supplements]
                        data[:na_prefix][:na_supplements]
                      elsif data[:na_supplements]
                        # Fallback to top level if structure differs
                        data[:na_supplements]
                      else
                        nil
                      end

        na_supp_data = if na_supp_raw
                         extract_supplements_from_array(Array(na_supp_raw))
                       else
                         []
                       end

        # Convert NA supplements to Amendment/Corrigendum objects with short year expansion
        na_supps = na_supp_data.map do |supp|
          # Expand short years to full years (15 -> 2015, 18 -> 2018)
          year_val = supp[:year]&.to_s
          if year_val && year_val.length == 2
            year_int = year_val.to_i
            # Assume 20XX for years 00-99
            year_val = (2000 + year_int).to_s
          end

          if supp[:type] == :amendment
            Identifiers::Amendment.new(
              base: nil, # NA supplements don't wrap base
              amendment_number: supp[:number],
              amendment_year: year_val&.to_i,
              separator: supp[:separator] || "+",
            )
          else
            Identifiers::Corrigendum.new(
              base: nil,
              corrigendum_number: supp[:number],
              corrigendum_year: year_val&.to_i,
              separator: supp[:separator] || "+",
            )
          end
        end

        Identifiers::NationalAnnex.new(
          na_supplements: na_supps,
          base_doc: base_id,
        )
      end

      def extract_supplements_from_array(supps_array)
        return [] if supps_array.empty?

        supps_array.map do |s|
          supp_data = s.is_a?(Hash) && s[:supplement] ? s[:supplement] : s

          # Determine separator - slash vs plus
          separator = supp_data[:amd_sep_slash] ? "/" : "+"

          {
            type: supp_data[:amd_number] ? :amendment : :corrigendum,
            number: (supp_data[:amd_number] || supp_data[:cor_number])&.to_s,
            year: (supp_data[:amd_year] || supp_data[:cor_year])&.to_s,
            separator: separator,
            amd_suffix_form: !(supp_data[:amd_sep_plus] || supp_data[:amd_sep_slash]),
          }
        end
      end

      def locate_identifier_klass(parsed_hash)
        # Special case: Flex documents
        return Identifiers::Flex if parsed_hash[:flex_type]

        # Special case: National Annex prefix
        return Identifiers::NationalAnnex if parsed_hash[:na_prefix]

        # Special case: Aerospace/Specialized prefix (BS A, BS AU, BS 2A, etc.)
        return Identifiers::AerospaceStandard if parsed_hash[:prefix]

        # Special case: Handle adopted identifiers
        # Match "EN " followed by digit (not "EN ISO" or "EN IEC")
        return Identifiers::AdoptedEuropeanNorm if parsed_hash[:adopted_string]&.match?(/^EN\s+\d/)
        return Identifiers::AdoptedInternationalStandard if parsed_hash[:adopted_string]

        # Use type to determine class via Pubid::Bsi.locate_stage / locate_type.
        # Unknown abbreviations fall back to DEFAULT_TYPED_STAGE (published BS).
        type_str = parsed_hash[:type] || parsed_hash[:stage] || ""
        typed_stage = Bsi.locate_stage(type_str.to_s.upcase) || DEFAULT_TYPED_STAGE
        Bsi.locate_type(typed_stage.type_code) || Identifiers::BritishStandard
      end

      def cast(type, value)
        case type
        when :type
          # Lookup from register via Pubid::Bsi.locate_stage.
          # Unknown abbreviations fall back to DEFAULT_TYPED_STAGE (published BS).
          typed_stage = Bsi.locate_stage(value.to_s.upcase) || DEFAULT_TYPED_STAGE
          {
            stage: typed_stage.to_stage,
            type: typed_stage.to_type,
            typed_stage: typed_stage,
            original_abbr: value.to_s, # Preserve original abbreviation
          }

        when :publisher
          Components::Publisher.new(body: value.to_s)

        when :prefix
          # Specialized prefix (A, AU, C, M, 2A, etc.)
          value&.to_s

        when :flex_prefix
          # Flex type prefix (CECC, E9111, M, etc.)
          value&.to_s

        when :number
          Components::Code.new(value: value.to_s)

        when :parts
          # Extract parts - handle both formats:
          # 1. Multi-level with separate keys: {:part=>"2", :subpart=>"1"}
          # 2. Combined format: {:part=>"2-1"} (split by dash)
          parts_array = Array(value)
          if parts_array.any?
            first_part = parts_array.first
            part_str = first_part[:part].to_s

            # Check if subpart is already separated (new format from part_with_subpart rule)
            if first_part.key?(:subpart)
              {
                part: Components::Code.new(value: part_str),
                subpart: Components::Code.new(value: first_part[:subpart].to_s),
              }
            else
              # Old format - split on dash to get part and subpart
              part_components = part_str.split("-")
              result = { part: Components::Code.new(value: part_components.first) }
              if part_components.length > 1
                result[:subpart] =
                  Components::Code.new(value: part_components[1])
              end
              result
            end
          end

        when :part
          Components::Code.new(value: value[:part].to_s) if value.is_a?(Hash)

        when :subpart
          Components::Code.new(value: value.to_s)

        when :year, :date
          # Only create date if value is present
          if value.nil?
            nil
          else
            { date: Components::Date.new(year: value.to_i) }
          end

        when :month
          value.to_i

        when :edition
          value.to_s

        when :flex_type, :na_prefix
          # Don't cast, used for class selection only
          nil

        when :adopted_string
          # Handle both string and nested hash formats
          # Parser may return: "EN ISO 13485 Expert Commentary" (string)
          # or: {:adopted_string_content=>" EN ISO 13485 Expert Commentary"} (hash)
          if value.is_a?(Hash) && value[:adopted_string_content]
            value[:adopted_string_content].to_s.strip
          else
            value.to_s.strip
          end

        when :supplements
          # Handled separately by extract_supplements
          nil

        when :expert_commentary
          # Handle nested hash from parser
          # Parser returns: {:expert_commentary_topic=>"Fire"} or {:expert_commentary_full=>"Expert Commentary"}
          if value.is_a?(Hash)
            if value[:expert_commentary_topic]
              @original_data[:expert_commentary_topic] =
                value[:expert_commentary_topic].to_s
            end
            if value[:expert_commentary_full]
              @original_data[:expert_commentary_full] =
                value[:expert_commentary_full].to_s
            end
          end
          true

        when :expert_commentary_full
          # Don't cast, used for format detection
          nil

        when :expert_commentary_topic
          # Don't cast, used for format detection
          nil

        when :pdf_format, :tc_format, :book_format
          # Don't cast, used for VAP wrapper construction
          nil

        when :translation_lang
          # Extract just the language name (e.g., "German", "Italian")
          value.to_s.capitalize

        when :translation_upper
          # Uppercase translation like "SPANISH" -> "Spanish"
          value.to_s.capitalize

        when :second_number
          # For collections like PAS 2035/2030
          Components::Code.new(value: value.to_s)

        when :iteration
          # For bracket notation like 1000[9]
          value.to_s

        when :index_identifier
          # Don't cast, handled by build_index
          nil

        when :index_suffix
          # Don't cast, handled by build_index
          nil

        when :method_identifier
          # Don't cast, handled by build_method
          nil

        when :method_suffix
          # Don't cast, handled by build_method
          nil

        when :section_identifier
          # Don't cast, handled by build_section
          nil

        when :section_suffix
          # Don't cast, handled by build_section
          nil

        when :detailed_specification
          # Don't cast, handled by build_detailed_specification
          nil

        when :detailed_spec_suffix
          # Don't cast, handled by build_detailed_specification
          nil

        when :spec_code
          Components::Code.new(value: value.to_s)

        when :amendment_number
          Components::Code.new(value: value.to_s)

        when :corrigendum
          !value.nil?

        when :parenthesized_amd
          # Don't cast, used for format detection
          nil

        when :standalone_amendment
          # Don't cast, handled by build_standalone_amendment
          nil

        else
          value
        end
      end

      def build_adopted_identifier(data)
        # Extract the actual adopted string value from the parsed data
        # The parser may produce nested hash: {:adopted_string=>{:adopted_string=>"ISO 37101:2016"}}
        adopted_str_value = data[:adopted_string]
        adopted_str = if adopted_str_value.is_a?(Hash)
                        adopted_str_value[:adopted_string] || adopted_str_value[:adopted_string_no_expert]
                      else
                        adopted_str_value
                      end
        adopted_str = adopted_str.to_s.strip if adopted_str

        return nil unless adopted_str && !adopted_str.empty?

        # Check if this is a bare adopted identifier (no BSI/BS/PD prefix)
        # If data has no publisher/type/na_prefix/flex_type, it's a bare adopted identifier
        is_bare = !data[:publisher] && !data[:type] && !data[:na_prefix] && !data[:flex_type] && !data[:stage]

        # Extract ExComm suffix before parsing (it should be preserved in data[:expert_commentary])
        # Remove it from adopted_string so ISO/IEC parsers don't choke on it
        # Handle all three formats: "Expert Commentary", "ExComm", "ExComm (Fire)"
        # Expert-commentary suffix matching is case-insensitive; output is always
        # canonicalised to "Expert Commentary" / "ExComm".
        if adopted_str.match?(/expert commentary$/i)
          adopted_str = adopted_str.sub(/expert commentary$/i, "")
          data[:expert_commentary_full] = "Expert Commentary"
          data[:expert_commentary] = true unless data.key?(:expert_commentary)
          # Update @original_data so wrap_with_expert_commentary can access it
          @original_data[:expert_commentary_full] = "Expert Commentary"
          unless @original_data.key?(:expert_commentary)
            @original_data[:expert_commentary] =
              true
          end
        elsif adopted_str.match?(/excomm \($/i)
          adopted_str = adopted_str.sub(/excomm \(.*\)$/i, "")
          data[:expert_commentary_full] = "Expert Commentary"
          data[:expert_commentary] = true unless data.key?(:expert_commentary)
          @original_data[:expert_commentary_full] = "Expert Commentary"
          unless @original_data.key?(:expert_commentary)
            @original_data[:expert_commentary] =
              true
          end
        elsif adopted_str.match?(/excomm \(/i)
          # Extract topic from "ExComm (Fire)"
          topic_match = adopted_str.match(/excomm\s*\(([^)]+)\)/i)
          adopted_str = adopted_str.sub(/excomm\s*\(.*\)$/i, "")
          data[:expert_commentary_topic] = topic_match[1] if topic_match
          data[:expert_commentary] = true unless data.key?(:expert_commentary)
          if topic_match
            @original_data[:expert_commentary_topic] =
              topic_match[1]
          end
          unless @original_data.key?(:expert_commentary)
            @original_data[:expert_commentary] =
              true
          end
        elsif adopted_str.match?(/excomm\s*$/i)
          # Abbreviated form "ExComm" at the end
          adopted_str = adopted_str.sub(/excomm\s*$/i, "")
          data[:expert_commentary] = true unless data.key?(:expert_commentary)
          unless @original_data.key?(:expert_commentary)
            @original_data[:expert_commentary] =
              true
          end
        end

        # NEW: Extract translation suffix before parsing
        # Handle parenthetical format: "(French version)", "(Spanish Translation)"
        # We need to track whether "version" or "Translation" was present
        if adopted_str.match?(/\s*\([A-Za-z]+(?:\s+(?:Translation|version))?\)\s*$/)
          translation_match = adopted_str.match(/\s*\(([A-Za-z]+)(?:\s+(Translation|version))?\)\s*$/)
          if translation_match
            data[:translation_lang] = translation_match[1]
            # Track if "version" or "Translation" suffix was present
            if translation_match[2]
              data[:translation_suffix_type] =
                translation_match[2]
            end
            adopted_str = adopted_str.sub(
              /\s*\([A-Za-z]+(?:\s+(?:Translation|version))?\)\s*$/, ""
            )
          end
        # Handle all-caps format: "FRENCH TRANSLATION"
        elsif adopted_str.match?(/\s+(SPANISH|FRENCH|GERMAN|ITALIAN)\s+TRANSLATION\s*$/)
          translation_upper_match = adopted_str.match(/\s+(SPANISH|FRENCH|GERMAN|ITALIAN)\s+TRANSLATION\s*$/)
          if translation_upper_match
            data[:translation_upper] = translation_upper_match[1]
            # Track that "Translation" suffix was present
            data[:translation_suffix_type] = "Translation"
            adopted_str = adopted_str.sub(
              /\s+(SPANISH|FRENCH|GERMAN|ITALIAN)\s+TRANSLATION\s*$/, ""
            )
          end
        end

        # Only extract edition if NOT bare - bare identifiers should preserve edition internally
        edition_match = is_bare ? nil : adopted_str.match(/\s+ED(\d+)\s*$/)
        extracted_edition = edition_match ? edition_match[1] : nil
        # Remove edition from adopted string for recursive parsing (only if extracted)
        adopted_str_clean = if edition_match
                              adopted_str.sub(/\s+ED\d+\s*$/,
                                              "")
                            else
                              adopted_str
                            end

        # Use extracted edition if no edition in data
        final_edition = data[:edition] || extracted_edition

        # NEW: Extract reaffirmation notation like (R2004) before parsing
        # This is used for documents that have been reaffirmed
        # Example: "DD ISO/IEC 11177-1:1995 (R2004)"
        if adopted_str_clean.match?(/\s+\(R(\d{4})\)\s*$/)
          reaffirmation_match = adopted_str_clean.match(/\s+\(R(\d{4})\)\s*$/)
          if reaffirmation_match
            data[:reaffirmation_year] = reaffirmation_match[1]
            adopted_str_clean = adopted_str_clean.sub(/\s+\(R\d{4}\)\s*$/, "")
          end
        end

        # NEW: Extract BSI-style supplements from adopted_string before delegating to ISO/IEC
        # BSI uses +A1:2020 format, but ISO/IEC parsers can't handle this
        # Patterns: +A1:2020, +A11:2021, +AMD1:2001, +C1:2020
        extracted_supplements = []
        # Match patterns like: +A1:2020, +A11:2021, +AMD1:2001, +C1:2020, +COR1:2020,
        # and the year-less compact forms +A2 / +C1 (the ":YYYY" is optional).
        # Must be at end of string or followed by space (not colon, which is part of date)
        adopted_str_clean = adopted_str_clean.gsub(/([+])(A(\d+)|AMD(\d+)|C(\d+)|COR(\d+))(?::(\d{4}))?(?:\s|$)/) do |_match|
          separator = $1 # "+" or "/"
          type_code = $2 || $3 || $4 || $5 || $6
          $2 || $3 || $4 || $5 || $6
          year = $7

          # Determine supplement type
          supp_type = if type_code.start_with?("A", "AMD")
                        :amendment
                      elsif type_code.start_with?("C", "COR")
                        :corrigendum
                      end

          # Extract number from type code (A1 -> 1, AMD1 -> 1, C1 -> 1)
          supp_number = if type_code.start_with?("AMD")
                          type_code.sub("AMD", "")
                        else
                          type_code.sub(/^[AC]/, "")
                        end

          extracted_supplements << {
            type: supp_type,
            number: supp_number,
            year: year,
            separator: separator,
            # compact "+A"/"/A" join form (not the trailing " AMD5" suffix form)
            amd_suffix_form: false,
          }

          "" # Remove from adopted_string
        end.strip

        # Extract AMD without year - "AMD5" or "AMD AA"
        # These don't have + or / prefix and don't have a year
        # Note: \s* (optional whitespace) after AMD to handle "AMD5" vs "AMD 5"
        adopted_str_clean = adopted_str_clean.gsub(/\s+AMD\s*(AA|\d+)(?:\s|$)/i) do |match|
          amd_number = match.strip.sub(/^AMD\s*/i, "")
          extracted_supplements << {
            type: :amendment,
            number: amd_number,
            year: nil,
            separator: nil, # No separator for AMD without year
            amd_suffix_form: true, # trailing " AMD5" suffix form
          }
          "" # Remove from adopted_string
        end.strip

        # Determine the BSI prefix to use (BS, PD, DD)
        bsi_prefix = if data[:type]
                       data[:type].to_s # PD, DD, etc.
                     elsif data[:publisher]
                       data[:publisher].to_s # BS
                     else
                       "BS" # Default
                     end

        # Multi-level adoption hierarchy (check most specific first):
        # 1. BS EN ISO/IEC (triple-level)
        # 2. BS ISO/IEC (double-level)
        # 3. BS EN (double-level)
        # 4. Bare ISO/IEC/EN (return as-is)

        adopted_id = nil

        # Check for EN ISO or EN IEC patterns (triple-level)
        if adopted_str_clean.match?(/EN\s+(ISO\/IEC|IEC|ISO)/)
          # Parse the ISO/IEC part
          iso_iec_str = adopted_str_clean.sub(/^EN\s+/, "")

          if iso_iec_str.start_with?("ISO/IEC") || iso_iec_str.include?("ISO/IEC")
            adopted_id = Pubid::Iso.parse(iso_iec_str)
          elsif iso_iec_str.start_with?("ISO")
            adopted_id = Pubid::Iso.parse(iso_iec_str)
          elsif iso_iec_str.start_with?("IEC")
            adopted_id = Pubid::Iec.parse(iso_iec_str)
          end

          # Wrap ISO/IEC identifier in EN adoption
          if adopted_id
            adopted_id = Pubid::CenCenelec::Identifiers::AdoptedEuropeanNorm.new(
              publisher: ["EN"],
              adopted_identifier: adopted_id,
            )
          end

        # Check for direct ISO/IEC patterns (double-level: BS ISO, BS IEC or bare ISO/IEC)
        elsif adopted_str_clean.start_with?("ISO/IEC") || adopted_str_clean.include?("ISO/IEC")
          adopted_id = Pubid::Iso.parse(adopted_str_clean)
        elsif adopted_str_clean.start_with?("ISO")
          adopted_id = Pubid::Iso.parse(adopted_str_clean)
        elsif adopted_str_clean.start_with?("IEC")
          adopted_id = Pubid::Iec.parse(adopted_str_clean)

        # Check for EN patterns (double-level: BS EN or DD/PD CEN) or CEN types
        elsif adopted_str_clean.start_with?("EN", "CEN", "CLC", "CR", "ES",
                                            "ENV", "HD", "CWA")
          adopted_id = Pubid::CenCenelec.parse(adopted_str_clean)
        # Check for CISPR
        elsif adopted_str_clean.start_with?("CISPR")
          adopted_id = Pubid::Iec.parse(adopted_str_clean)
        end

        # If this is a bare adopted identifier (no BSI prefix), return it as-is
        return adopted_id if is_bare && adopted_id

        # Return appropriate wrapper based on adoption type
        if adopted_id
          # If adopted_id is a CEN identifier (in Cen module), use AdoptedEuropeanNorm
          # The Expert-commentary suffix is represented uniformly by an outer
          # ExpertCommentary wrapper (below), never a boolean on the inner norm,
          # so that #base_document peels cleanly to the bare standard.
          identifier = if adopted_id.class.name.start_with?("Pubid::CenCenelec::")
                         Identifiers::AdoptedEuropeanNorm.new(
                           publisher: Components::Publisher.new(body: bsi_prefix),
                           adopted_identifier: adopted_id,
                           edition: final_edition&.to_s,
                           translation_lang: data[:translation_lang]&.to_s,
                           translation_upper: data[:translation_upper]&.to_s,
                           # Pass translation_suffix_type for rendering
                           translation_suffix_type: data[:translation_suffix_type]&.to_s,
                           # Pass reaffirmation_year for rendering
                           reaffirmation_year: data[:reaffirmation_year]&.to_s,
                         )
                       else
                         # Otherwise it's ISO/IEC, use AdoptedInternationalStandard
                         Identifiers::AdoptedInternationalStandard.new(
                           publisher: Components::Publisher.new(body: bsi_prefix),
                           adopted_identifier: adopted_id,
                           edition: final_edition&.to_s,
                           translation_lang: data[:translation_lang]&.to_s,
                           translation_upper: data[:translation_upper]&.to_s,
                           # Pass translation_suffix_type for rendering
                           translation_suffix_type: data[:translation_suffix_type]&.to_s,
                           # Pass reaffirmation_year for rendering
                           reaffirmation_year: data[:reaffirmation_year]&.to_s,
                         )
                       end

          # Wrap supplements first (they render before the ExComm suffix), then
          # wrap the whole thing in a single ExpertCommentary — same shape as the
          # pure-BSI path, keeping #base_document uniform.
          if extracted_supplements.any?
            identifier = wrap_with_consolidated(identifier, extracted_supplements)
          end
          if data[:expert_commentary] || data[:expert_commentary_full]
            identifier = wrap_with_expert_commentary(identifier)
          end

          identifier
        end
      end

      def wrap_with_consolidated(base, supplements_data,
expert_commentary: nil, expert_commentary_topic: nil)
        # If expert_commentary data is provided, set it on the base
        # This allows ConsolidatedIdentifier to render the ExComm suffix correctly
        if expert_commentary
          base_attrs = base.class.attributes
          if base_attrs.key?(:expert_commentary)
            base.expert_commentary = expert_commentary
          end
          if expert_commentary_topic && base_attrs.key?(:expert_commentary_topic)
            base.expert_commentary_topic = expert_commentary_topic
          end
        end

        supplement_ids = supplements_data.map do |supp|
          # Expand short years to full years (15 -> 2015, 18 -> 2018)
          year_val = supp[:year]&.to_s
          if year_val && year_val.length == 2
            year_int = year_val.to_i
            # Assume 20XX for years 00-99
            year_val = (2000 + year_int).to_s
          end

          if supp[:type] == :amendment
            Identifiers::Amendment.new(
              base: base,
              amendment_number: supp[:number],
              amendment_year: year_val&.to_i,
              separator: supp[:separator] || "+",
              amd_suffix_form: supp[:amd_suffix_form] ? true : false,
            )
          else
            Identifiers::Corrigendum.new(
              base: base,
              corrigendum_number: supp[:number],
              corrigendum_year: year_val&.to_i,
              separator: supp[:separator] || "+",
            )
          end
        end

        Identifiers::ConsolidatedIdentifier.new(
          identifiers: [base] + supplement_ids,
        )
      end

      def extract_supplements(data)
        return [] unless data[:supplements]

        supps_array = data[:supplements]
        return [] if supps_array.empty?

        supps_array.map do |s|
          supp_data = s.is_a?(Hash) && s[:supplement] ? s[:supplement] : s

          # Determine separator - slash vs plus
          separator = supp_data[:amd_sep_slash] ? "/" : "+"

          {
            type: supp_data[:amd_number] ? :amendment : :corrigendum,
            number: (supp_data[:amd_number] || supp_data[:cor_number])&.to_s,
            year: (supp_data[:amd_year] || supp_data[:cor_year])&.to_s,
            separator: separator,
            # The compact "+A"/"/A" amendment rule captures an explicit separator;
            # the trailing " AMD5" suffix form does not.
            amd_suffix_form: !(supp_data[:amd_sep_plus] || supp_data[:amd_sep_slash]),
          }
        end
      end
    end
  end
end
