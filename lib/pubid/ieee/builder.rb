# frozen_string_literal: true

module Pubid
  module Ieee
    # Builder class for constructing IEEE identifier scheme from parsed data
    # Single Responsibility: Transform parsed data into identifier objects
    class Builder
      attr_accessor :original_input
      attr_reader :identifier_class

      def initialize(identifier_class = Identifier)
        @identifier_class = identifier_class
      end

      # Build a scheme object from parsed data
      # @param parsed [Hash, Array] the parsed identifier data
      # @return [identifier] the constructed identifier object
      def build(parsed)
        # Handle CSA dual published patterns
        if parsed[:ieee_portion] && parsed[:csa_portion]
          return build_csa_dual_published(parsed)
        end

        # Handle the historical IEEE/IPCEA cable designation (S-135)
        if parsed[:s_number]
          return build_s_designation(parsed)
        end

        # Handle combined AIEE identifiers (from "Nos X and Y" preprocessing)
        if parsed[:first_aiee] && parsed[:second_aiee]
          return build_combined_aiee(parsed)
        end

        # Handle dual published patterns
        if parsed[:first] && parsed[:second]
          return build_dual_published(parsed)
        end

        # Handle IEC/IEEE copublished patterns
        if parsed[:content]
          return build_iec_ieee_copublished(parsed)
        end

        # Handle NESC identifiers (National Electrical Safety Code)
        if parsed[:nesc]
          nesc_builder = Nesc::Builder.new
          return nesc_builder.build(parsed[:nesc])
        end

        # Handle AIEE identifiers (American Institute of Electrical Engineers)
        if parsed[:aiee]
          aiee_builder = Aiee::Builder.new
          return aiee_builder.build(parsed[:aiee])
        end

        # Handle IRE identifiers (Institute of Radio Engineers)
        if parsed[:ire]
          ire_builder = Ire::Builder.new
          return ire_builder.build(parsed[:ire])
        end

        # Handle IEEE/ASTM SI/PSI identifiers (Système International)
        if parsed[:si_type]
          return build_si_psi_identifier(parsed)
        end

        # Handle single identifier
        build_single_identifier(parsed)
      end

      private

      # Build IEC/IEEE copublished identifier
      def build_iec_ieee_copublished(parsed)
        content = extract_value(parsed[:content])

        # Parse the content to extract components
        copublished_number = nil
        draft_info = nil
        iec_year = nil
        date_info = nil

        if content
          # Extract copublished number (everything before IEC: or comma or parenthesis)
          copublished_number = if content.include?("IEC:")
                                 content.split(" IEC:").first.strip
                               elsif content.include?(", ")
                                 content.split(", ").first.strip
                               elsif content.include?(" (")
                                 content.split(" (").first.strip
                               else
                                 content.strip
                               end

          # Extract draft info if present
          if copublished_number.include?("/D")
            parts = copublished_number.split("/D")
            copublished_number = parts[0]
            draft_info = "/D#{parts[1] || ''}"
          end

          # Extract IEC year if present
          if content.include?("IEC:")
            iec_part = content.split("IEC:")[1]
            if iec_part
              iec_year = iec_part.split.first
            end
          end

          # Extract date info if present
          if content.include?(" (")
            date_part = content.split(" (")[1]
            if date_part&.include?(")")
              date_info = date_part.split(")")[0]
            end
          end
        end

        Identifiers::IecIeeeCopublished.new(
          draft_info: draft_info,
          iec_year: iec_year,
          date_info: date_info,
          **copublished_structured(copublished_number),
        )
      end

      # Decompose an IEC/IEEE `copublished_number` into the split index columns
      # that reconstruct it losslessly (IecIeeeCopublished#copublished_number is
      # the inverse). First peel a trailing *publication year* (19xx/20xx with
      # its `-`/`:` separator) into `year`/`year_sep` — a bare 4-digit strip
      # would wrongly eat a part like "60076.57-1202" (1202 is a part, not a
      # year). Then tokenise the remainder on `.`/`-`, keeping each part's
      # leading separator (a single code mixes them). So `number` narrows to the
      # bucket, `parts` matches within it, and `separators` renders it back.
      # `year_sep` is omitted when the default `-`. Returns empty for no number.
      def copublished_structured(copublished_number)
        return {} if copublished_number.nil? || copublished_number.empty?

        remainder, year, year_sep = peel_copublished_year(copublished_number)
        tokens = remainder.scan(/\A[^.\-]+|[.\-][^.\-]+/)
        { number: tokens.shift }
          .merge(copublished_parts(tokens))
          .merge(copublished_year(year, year_sep))
      end

      # The `parts`/`separators` columns from the tokens after the number.
      def copublished_parts(tokens)
        return {} if tokens.empty?

        { parts: tokens.map { |t| t[1..] }, separators: tokens.map { |t| t[0] } }
      end

      # The `year`/`year_sep` columns; `year_sep` is omitted when the default `-`.
      def copublished_year(year, year_sep)
        return {} unless year

        year_sep == "-" ? { year: year } : { year: year, year_sep: year_sep }
      end

      # Peel a trailing publication year (19xx/20xx with its `-`/`:` separator)
      # off a copublished number, returning [remainder, year, year_sep].
      def peel_copublished_year(copublished_number)
        return [copublished_number, nil, nil] unless
          copublished_number =~ /([-:])((?:19|20)\d\d)\z/

        year_sep = Regexp.last_match(1)
        year = Regexp.last_match(2)
        trimmed = copublished_number[0...(copublished_number.length -
          year_sep.length - year.length)]
        [trimmed, year, year_sep]
      end

      # Build dual published identifier
      def build_dual_published(parsed)
        first_id = build_single_identifier(parsed[:first])
        second_id = build_single_identifier(parsed[:second])

        Identifiers::DualPublished.new(
          first_identifier: first_id,
          second_identifier: second_id,
        )
      end

      # Build CSA dual published identifier
      # @param parsed [Hash] parsed CSA dual published data
      # @return [Identifiers::CsaDualPublished] CSA dual published identifier
      def build_csa_dual_published(parsed)
        # Build IEEE portion
        ieee_id = build_single_identifier(parsed[:ieee_portion])

        # Extract and parse CSA portion using CSA parser
        csa_string = extract_value(parsed[:csa_portion])

        # Prepend "CSA " prefix if not present (CSA parser expects this format)
        csa_string = "CSA #{csa_string}" unless csa_string.start_with?("CSA",
                                                                       "CAN/")

        # Use CSA parser to parse the CSA portion
        csa_id = Pubid::Csa.parse(csa_string)

        Identifiers::CsaDualPublished.new(
          ieee_identifier: ieee_id,
          csa_identifier: csa_id,
        )
      end

      # Build the historical IEEE/IPCEA cable designation (e.g. S-135).
      #
      # The "S-135" designation is modelled as a plain Standard whose code holds
      # the whole "S-135" string as `number` (prefix nil). It is passed as the
      # `number:` split column directly — NOT as `code:` — so it bypasses
      # Components::Code.parse, which would peel "S" as a prefix and leave an
      # empty number (breaking the relaton index key and the round-trip). This
      # keeps `root.number` == "S-135" and renders the dash back verbatim.
      #
      # The "/IPCEA …" slash co-designation is stored verbatim in `crossref`
      # (rendered as-is); the "(IPCEA …)" parenthetical variant flows through
      # the normal `parenthetical_content` path.
      def build_s_designation(parsed)
        attributes = {
          number: extract_value(parsed[:s_number]),
          publisher: extract_value(parsed[:publisher]) || "IEEE",
          typed_stage: Pubid::Ieee.locate_stage("Std"),
        }

        if parsed[:ipcea_copub]
          attributes[:crossref] = extract_value(parsed[:ipcea_copub])
        end
        handle_parameters(parsed, attributes)

        Identifiers::Standard.new(**attributes)
      end

      # Build single identifier
      def build_single_identifier(parsed, building_secondary: false)
        # Parslet can return array of hashes - merge them
        parsed_hash = parsed.is_a?(Array) ? merge_parsed_array(parsed) : parsed

        # Handle multi-numbered identifiers (cross-reference and joint standards)
        # CRITICAL: Don't recurse when building secondary identifier to prevent infinite loop
        if !building_secondary && parsed_hash[:primary_identifier] && (parsed_hash[:secondary_crossref] || parsed_hash[:secondary_joint])
          return build_multi_numbered_identifier(parsed_hash)
        end

        # Handle corrigendum supplements (check for base + cor_number)
        # This enables recursive base identifier parsing like ISO/IEC Amendment
        if parsed_hash[:base] && parsed_hash[:cor_number]
          return build_corrigendum_supplement(parsed_hash)
        end

        # Handle the flat draft + corrigendum form (relaton's `…/D-N/CorM-YYYY`,
        # normalized to `…/Cor M-YYYY/D N`): the parser emits a top-level
        # `corrigendum` hash alongside `draft`/number with NO `:base` subtree, so
        # the supplement path above is skipped. Rebuild a real base standard
        # (carrying the draft) and wrap it, so `to_s` renders correctly from a
        # fresh parse and after a from_hash round-trip. The `!parsed_hash[:base]`
        # guard keeps this disjoint from the nested-base branch above; a
        # `:base` + nested-`corrigendum`-hash shape is not produced by the
        # grammar, so it would fall through to `extract_attributes` (as before).
        if parsed_hash[:corrigendum].is_a?(Hash) && !parsed_hash[:base]
          return build_flat_corrigendum(parsed_hash)
        end

        # Handle interpretation supplements (check for base + int_year)
        if parsed_hash[:base] && (parsed_hash[:int_year] || parsed_hash[:interpretation])
          return build_interpretation_supplement(parsed_hash)
        end

        # Handle conformance supplements (check for base + conf_number)
        if parsed_hash[:base] && parsed_hash[:conf_number]
          return build_conformance_supplement(parsed_hash)
        end

        # Handle joint development patterns from parser
        if parsed_hash[:joint_publishers] || parsed_hash[:iso_stage]
          return build_joint_development(parsed_hash)
        end

        attributes = extract_attributes(parsed_hash)

        # Handle relationships if present (Pattern 4)
        if parsed_hash[:relationship_type] || parsed_hash[:relationship_clause]
          attributes[:relationships] = build_relationships(parsed_hash)
        end

        # Route to appropriate identifier class based on content
        identifier_class = determine_identifier_class(attributes)
        rename_supplement_keys(attributes)
        identifier_class.new(**attributes)
      end

      # Supplement wrappers (Corrigendum/Conformance/Interpretation) store their
      # ordinal/year under the uniform `number`/`year`, but the parse tree and
      # class-routing above key on the distinct `cor_*`/`conf_*`/`int_year`
      # names. Translate them **after** routing, just before construction. Guards
      # ensure a plain standard's own `number`/`year` are never overwritten (it
      # carries none of these keys).
      def rename_supplement_keys(attributes)
        ordinal = attributes.delete(:cor_number) || attributes.delete(:conf_number)
        attributes[:number] = ordinal if ordinal
        year = attributes.delete(:cor_year) || attributes.delete(:conf_year) ||
          attributes.delete(:int_year)
        attributes[:year] = year if year
      end

      # Build corrigendum supplement with recursive base parsing
      # @param parsed_hash [Hash] parsed data with base and supplement info
      # @return [Identifiers::Corrigendum] corrigendum identifier
      def build_corrigendum_supplement(parsed_hash)
        # Reconstruct base identifier string from parsed components
        base_parts = []
        base_data = parsed_hash[:base]

        # Extract publisher
        if base_data[:publishers]
          pub_data = base_data[:publishers]
          publisher_str = extract_value(pub_data[:publisher])

          if pub_data[:copublishers] && !pub_data[:copublishers].empty?
            copubs = pub_data[:copublishers]
            copubs = [copubs] unless copubs.is_a?(Array)
            copub_strs = copubs.filter_map do |cp|
              extract_value(cp[:copublisher])
            end
            publisher_str += "/#{copub_strs.join('/')}" if !copub_strs.empty?
          end

          base_parts << publisher_str
        end

        # Extract type
        if base_data[:type]
          base_parts << extract_value(base_data[:type])
        end

        # Extract number with parts and year
        # Build the complete code string: "802.1AC-2016" or "535-2013" or "C37.41-2016"
        number_str = extract_value(base_data[:number])

        # Add part if present (e.g., ".1AC" or ".41")
        if base_data[:part]
          part_val = extract_value(base_data[:part])
          # Determine separator: dot for most cases, dash for some
          separator = number_str.match?(/^[A-Z]/) ? "." : "." # Letter prefix uses dot
          number_str += separator + part_val
        end

        # Add subpart if present
        if base_data[:subpart]
          subparts = base_data[:subpart]
          subparts = [subparts] unless subparts.is_a?(Array)
          subparts.each do |sp|
            subpart_val = extract_value(sp)
            number_str += ".#{subpart_val}" if subpart_val
          end
        end

        # Add year with dash (e.g., "-2016")
        if base_data[:year]
          year_val = extract_value(base_data[:year])
          number_str += "-#{year_val}"
        end

        base_parts << number_str

        # Build base string and recursively parse it
        base_string = base_parts.join(" ")

        # Recursively parse base identifier using Base.parse
        base = Identifier.parse(base_string)

        # Extract corrigendum attributes (parse-tree keys are cor_*; the
        # identifier stores them as the uniform `number`/`year`).
        cor_number = extract_value(parsed_hash[:cor_number])
        cor_year = extract_value(parsed_hash[:cor_year])

        # Create Corrigendum with parsed base
        Identifiers::Corrigendum.new(
          base: base,
          number: cor_number,
          year: cor_year,
        )
      end

      # Build a Corrigendum from the flat parse tree produced by the combined
      # `…/Cor M-YYYY/D N` form, where the corrigendum lives in a top-level
      # `corrigendum` hash and there is no `:base` subtree. Peel the corrigendum
      # off, build the remaining attributes into the base standard (with its
      # draft) via the normal single-identifier path, then wrap.
      # @param parsed_hash [Hash] flat parsed data with a :corrigendum hash
      # @return [Identifiers::Corrigendum]
      def build_flat_corrigendum(parsed_hash)
        cor_data = parsed_hash[:corrigendum]
        cor_number = extract_value(cor_data[:cor_number])
        cor_year = extract_value(cor_data[:cor_year]) if cor_data[:cor_year]

        base_hash = parsed_hash.reject { |key, _| key == :corrigendum }
        base = build_single_identifier(base_hash)

        Identifiers::Corrigendum.new(
          base: base,
          number: cor_number,
          year: cor_year,
        )
      end

      # Build interpretation supplement with recursive base parsing
      # @param parsed_hash [Hash] parsed data with base and supplement info
      # @return [Identifiers::InterpretationIdentifier] interpretation identifier
      def build_interpretation_supplement(parsed_hash)
        # Reconstruct base identifier string from parsed components (same logic as corrigendum)
        base_parts = []
        base_data = parsed_hash[:base]

        # Extract publisher
        if base_data[:publishers]
          pub_data = base_data[:publishers]
          publisher_str = extract_value(pub_data[:publisher])

          if pub_data[:copublishers] && !pub_data[:copublishers].empty?
            copubs = pub_data[:copublishers]
            copubs = [copubs] unless copubs.is_a?(Array)
            copub_strs = copubs.filter_map do |cp|
              extract_value(cp[:copublisher])
            end
            publisher_str += "/#{copub_strs.join('/')}" if !copub_strs.empty?
          end

          base_parts << publisher_str
        end

        # Extract type
        if base_data[:type]
          base_parts << extract_value(base_data[:type])
        end

        # Extract number with parts and year
        number_str = extract_value(base_data[:number])

        # Add part if present
        if base_data[:part]
          part_val = extract_value(base_data[:part])
          separator = number_str.match?(/^[A-Z]/) ? "." : "."
          number_str += separator + part_val
        end

        # Add subpart if present
        if base_data[:subpart]
          subparts = base_data[:subpart]
          subparts = [subparts] unless subparts.is_a?(Array)
          subparts.each do |sp|
            subpart_val = extract_value(sp)
            number_str += ".#{subpart_val}" if subpart_val
          end
        end

        # Add year with dash
        if base_data[:year]
          year_val = extract_value(base_data[:year])
          number_str += "-#{year_val}"
        end

        base_parts << number_str

        # Build base string and recursively parse it
        base_string = base_parts.join(" ")

        # Recursively parse base identifier using Base.parse
        base = Identifier.parse(base_string)

        # Extract interpretation attributes
        int_year = extract_value(parsed_hash[:int_year])

        # Create InterpretationIdentifier with parsed base (int_year -> year)
        Identifiers::InterpretationIdentifier.new(
          base: base,
          year: int_year,
        )
      end

      # Build conformance supplement with recursive base parsing
      # @param parsed_hash [Hash] parsed data with base and supplement info
      # @return [Identifiers::ConformanceIdentifier] conformance identifier
      def build_conformance_supplement(parsed_hash)
        # Reconstruct base identifier string from parsed components (same logic as corrigendum)
        base_parts = []
        base_data = parsed_hash[:base]

        # Extract publisher
        if base_data[:publishers]
          pub_data = base_data[:publishers]
          publisher_str = extract_value(pub_data[:publisher])

          if pub_data[:copublishers] && !pub_data[:copublishers].empty?
            copubs = pub_data[:copublishers]
            copubs = [copubs] unless copubs.is_a?(Array)
            copub_strs = copubs.filter_map do |cp|
              extract_value(cp[:copublisher])
            end
            publisher_str += "/#{copub_strs.join('/')}" if !copub_strs.empty?
          end

          base_parts << publisher_str
        end

        # Extract type
        if base_data[:type]
          base_parts << extract_value(base_data[:type])
        end

        # Extract number with parts and year
        number_str = extract_value(base_data[:number])

        # Add part if present
        if base_data[:part]
          part_val = extract_value(base_data[:part])
          separator = number_str.match?(/^[A-Z]/) ? "." : "."
          number_str += separator + part_val
        end

        # Add subpart if present
        if base_data[:subpart]
          subparts = base_data[:subpart]
          subparts = [subparts] unless subparts.is_a?(Array)
          subparts.each do |sp|
            subpart_val = extract_value(sp)
            number_str += ".#{subpart_val}" if subpart_val
          end
        end

        # Add year with dash
        if base_data[:year]
          year_val = extract_value(base_data[:year])
          number_str += "-#{year_val}"
        end

        base_parts << number_str

        # Build base string and recursively parse it
        base_string = base_parts.join(" ")

        # Recursively parse base identifier using Base.parse
        base = Identifier.parse(base_string)

        # Extract conformance attributes
        conf_number = extract_value(parsed_hash[:conf_number])
        conf_year = extract_value(parsed_hash[:conf_year])

        # Create ConformanceIdentifier with parsed base (conf_* -> number/year)
        Identifiers::ConformanceIdentifier.new(
          base: base,
          number: conf_number,
          year: conf_year,
        )
      end

      # Build joint development identifier from parsed data
      def build_joint_development(parsed)
        attributes = {}

        # Extract publishers from joint_publishers
        if parsed[:joint_publishers]
          joint_pub_str = extract_value(parsed[:joint_publishers])
          attributes[:publishers] = joint_pub_str.split("/")
        end

        # Build code with parts if present
        code_parts = []
        code_parts << extract_value(parsed[:part]) if parsed[:part]

        code_str = extract_value(parsed[:number])
        if code_str && !code_parts.empty?
          code_str += ".#{code_parts.join('.')}"
        end
        attributes[:code] = code_str

        # Extract year (and optional numeric month, e.g. the -MM of a historical
        # "…-2018-05" ISO-stage date)
        attributes[:year] = extract_value(parsed[:year]) if parsed[:year]
        attributes[:month] = extract_value(parsed[:month]) if parsed[:month]

        # Extract draft version if present (e.g., D8 from /D8). This applies to
        # both the ISO-led (bucket 5: "…FDIS P15289/D-3-2017") and IEEE-led
        # forms, so it lives before the lead-party split.
        if parsed[:draft_version]
          draft_ver = extract_value(parsed[:draft_version])
          # Remove leading 'D' if present since draft_version already has it
          draft_ver = draft_ver.sub(/^D/, "") if draft_ver
          attributes[:ieee_draft] = "D#{draft_ver}" if draft_ver
        end

        # Detect lead party based on pattern
        if parsed[:iso_stage]
          # ISO format - lead party is ISO
          attributes[:lead_party] = "ISO"
          attributes[:iso_stage] = extract_value(parsed[:iso_stage])

          # Create typed_stage for ISO stage
          stage_abbr = attributes[:iso_stage]
          if stage_abbr
            attributes[:typed_stage] =
              Pubid::Ieee.locate_stage(stage_abbr)
          end
        else
          # IEEE format - lead party is IEEE
          attributes[:lead_party] = "IEEE"

          # Mark as project (P prefix)
          attributes[:type] = "P"

          # Create typed_stage for IEEE project
          attributes[:typed_stage] =
            Pubid::Ieee.locate_stage("P")
        end

        Identifiers::JointDevelopment.new(**attributes)
      end

      # Build SI/PSI identifier from parsed data
      # @param parsed [Hash] parsed SI/PSI data
      # @return [Identifiers::SiStandard] SI or PSI identifier (both use same class)
      def build_si_psi_identifier(parsed)
        attributes = {}

        # Extract SI type (SI or PSI)
        si_type = extract_value(parsed[:si_type])

        # Extract publishers (should be "IEEE/ASTM")
        if parsed[:publishers]
          publishers_str = extract_value(parsed[:publishers])
          # Split by slash to get individual publishers
          pubs = publishers_str.split("/")
          attributes[:publisher] = pubs.first
          attributes[:copublisher] = pubs.drop(1) if pubs.length > 1
        end

        # Extract number
        attributes[:code] = extract_value(parsed[:number])

        # For PSI (draft), create proper Draft component object
        if si_type == "PSI"
          if parsed[:draft_version]
            draft_version = extract_value(parsed[:draft_version])
            # Create Draft component (Lutaml::Model object)
            attributes[:draft_obj] =
              Components::Draft.new(version: draft_version)
          end
          # Set PSI typed_stage (draft stage)
          attributes[:typed_stage] = Identifiers::SiStandard::TYPED_STAGES.find do |ts|
            ts.abbr.include?("PSI")
          end
        else
          # Set SI typed_stage (published stage)
          attributes[:typed_stage] = Identifiers::SiStandard::TYPED_STAGES.find do |ts|
            ts.abbr.include?("SI")
          end
        end

        # Extract year and month
        attributes[:year] = extract_value(parsed[:year]) if parsed[:year]
        attributes[:month] = extract_value(parsed[:month]) if parsed[:month]

        # Handle relationships if present
        if parsed[:relationship_type] || parsed[:relationship_clause]
          attributes[:relationships] = build_relationships(parsed)
        end

        # Handle parenthetical content
        handle_parameters(parsed, attributes)

        # BOTH SI and PSI use SiStandard class - just different typed_stages
        Identifiers::SiStandard.new(**attributes)
      end

      # Build multi-numbered identifier from parsed data
      # @param parsed [Hash] parsed multi-numbered data
      # @return [Identifiers::MultiNumberedIdentifier] multi-numbered identifier
      def build_multi_numbered_identifier(parsed)
        # Build primary identifier
        primary_id = build_single_identifier(parsed[:primary_identifier],
                                             building_secondary: false)

        # Build secondary identifier based on format
        if parsed[:secondary_crossref]
          # Cross-reference format: /C62.22.1-1996
          # Build directly to avoid re-parsing which could cause infinite recursion
          crossref = parsed[:secondary_crossref]
          # Pattern: slash >> "C" >> digits >> dot >> digits >> dot >> digits >> dash >> year_digits
          # The parsed crossref is a string - extract the number part
          # Format: C62.22.1-1996 where C is part of the crossref notation
          secondary_id = Identifiers::Standard.new(
            publisher: "IEEE",
            number: extract_value(crossref),
          )
        elsif parsed[:secondary_joint]
          # Joint standard format: ", Std 1177-1989"
          # Build from parsed components
          secondary_id = build_single_identifier(parsed[:secondary_joint],
                                                 building_secondary: true)
        else
          secondary_id = nil
        end

        Identifiers::MultiNumberedIdentifier.new(
          primary_identifier: primary_id,
          secondary_identifier: secondary_id,
        )
      end

      # Determine which identifier class to use based on attributes
      # CRITICAL: Use flavor module for type-based decisions, NOT hardcoded logic here
      # Builder's job is ONLY to cast types, not make business decisions
      def determine_identifier_class(attributes)
        # Check for AIEE publisher FIRST (AIEE has its own identifier class)
        # This must be checked before type-based routing because AIEE uses "No" as type
        if attributes[:publisher] == "AIEE"
          return Ieee::Aiee::Identifier
        end

        # Get type from attributes and use flavor module to locate class
        type_code = attributes[:type]

        # Use flavor module for type-to-class mapping
        if type_code
          klass = Pubid::Ieee.locate_type(type_code)
          return klass if klass
        end

        # Non-type-based routing (structural patterns, not business logic)
        # These are structural checks, not type decisions

        # Check for SI standards (handles both SI and PSI via typed_stage)
        if ["SI", "PSI"].include?(type_code)
          return Identifiers::SiStandard
        end

        # Check for interpretation supplements (structural: has interpretation flag or int_year)
        if attributes[:interpretation] || attributes[:int_year]
          return Identifiers::InterpretationIdentifier
        end

        # Check for conformance supplements (structural: has conf_number)
        if attributes[:conf_number]
          return Identifiers::ConformanceIdentifier
        end

        # Check for corrigendum supplements (structural: has cor_number)
        if attributes[:cor_number]
          return Identifiers::Corrigendum
        end

        # Check for multi-numbered standards (structural: has crossref or joint patterns)
        # These are handled at the build() method level, not here
        # (cross-reference patterns like /C62.22.1-1996 and joint standards)

        # Check for adopted standards (parenthetical adoptions)
        if attributes[:adoption] || (attributes[:parameters] && attributes[:parameters][:adoption])
          return Identifiers::AdoptedStandard
        end

        # Check for redline standards (structural: has redline flag)
        if attributes[:redline]
          return Identifiers::RedlinedStandard
        end

        # Default to the concrete Standard leaf (a plain published standard).
        # Routing to a leaf — rather than instantiating the shared base
        # Ieee::Identifier — is what lets `number` be a reliable :string index
        # key (see Identifiers::Standard).
        Identifiers::Standard
      end

      # Detect lead party for joint development identifiers
      # @param attributes [Hash] the identifier attributes
      # @return [String] the lead party ("IEEE", "ISO", or "IEC")
      def detect_lead_party(attributes)
        # Rule 1: Check for P prefix in code (IEEE-led)
        if attributes[:code]&.start_with?("P") || attributes[:type] == "P"
          return "IEEE"
        end

        # Rule 2: Check for IEEE draft notation in original input (IEEE-led)
        if original_input&.match?(/\/D\d+/)
          return "IEEE"
        end

        # Rule 3: Check for ISO stage codes (ISO-led)
        iso_stages = %w[FDIS DIS CD WD PWI NP]
        if attributes[:typed_stage]
          stage_abbr = attributes[:typed_stage].abbr
          stage_abbr = [stage_abbr] unless stage_abbr.is_a?(Array)
          if stage_abbr.any? { |abbr| iso_stages.include?(abbr) }
            return "ISO"
          end
        end

        # Rule 4: Check for colon before year in original input (ISO-led)
        if original_input&.match?(/:\d{4}/)
          return "ISO"
        end

        # Rule 5: Default to first publisher
        attributes[:publisher] || "IEEE"
      end

      # Merge an array of parsed hashes into a single hash
      # @param parsed_array [Array<Hash>] array of parsed hashes
      # @return [Hash] merged hash
      def merge_parsed_array(parsed_array)
        parsed_array.inject({}) do |result, hash|
          result.merge(hash)
        end
      end

      # Extract and normalize attributes from parsed data
      # @param parsed [Hash] the parsed data
      # @return [Hash] normalized attributes for identifier
      def extract_attributes(parsed)
        attributes = {}

        # Handle publishers
        if parsed[:publishers]
          pub_data = parsed[:publishers]
          attributes[:publisher] = extract_value(pub_data[:publisher])

          if pub_data[:copublishers]
            copubs = pub_data[:copublishers]
            copubs = [copubs] unless copubs.is_a?(Array)
            attributes[:copublisher] = copubs.filter_map do |cp|
              extract_value(cp[:copublisher])
            end
          end
        elsif parsed[:publisher]
          attributes[:publisher] = extract_value(parsed[:publisher])
        end

        # Build code component with parts and subparts
        code_parts = []
        code_parts << extract_value(parsed[:part]) if parsed[:part]
        if parsed[:subpart]
          subparts = parsed[:subpart]
          subparts = [subparts] unless subparts.is_a?(Array)
          code_parts.concat(subparts.filter_map { |sp| extract_value(sp) })
        end

        # Create code string with parts
        code_str = extract_value(parsed[:number])

        # Extract type and draft_status for typed_stage lookup
        type_value = extract_value(parsed[:type])
        draft_status_value = extract_value(parsed[:draft_status])

        # Handle case where parser captured number without "P" prefix
        # Check original input to see if there was a P before the number
        # The ieee_p_identifier rule consumes P without capturing it
        if !type_value && original_input&.match?(/IEEE\s+P/)
          type_value = "P"
        end

        # Handle ANSI P prefix patterns (e.g., "ANSI PN42.34-2015")
        if !type_value && original_input&.match?(/ANSI\s+P/)
          # Extract P as type since it was in the original but parser stripped it
          type_value = "P"
        end

        # NOTE: "P" is a project/draft stage indicator, NOT a code prefix
        # It should be reflected in typed_stage, not in the Code component
        # Do NOT prepend "P" to code_str - code.prefix should remain nil for project drafts

        # Special case: For IEEE/CSA dual published patterns, strip P prefix from code
        # Pattern: "IEEE/CSA P844.1-2017" -> code should be "844.1" not "P844.1"
        if code_str&.start_with?("P") && original_input&.include?("/CSA")
          # Check if the copublisher attribute indicates CSA
          pub_data = parsed[:publishers]
          has_csa_copub = if pub_data && pub_data[:copublishers]
                            copubs = pub_data[:copublishers]
                            copubs = [copubs] unless copubs.is_a?(Array)
                            copubs.any? do |cp|
                              extract_value(cp[:copublisher])&.include?("CSA")
                            end
                          else
                            original_input&.include?("/CSA")
                          end

          if has_csa_copub
            code_str = code_str.sub(/^P/, "")
          end
        end

        if code_str && !code_parts.empty?
          code_str += ".#{code_parts.join('.')}"
        end

        # Year detection: If code_str ends with year-like pattern (dash + 4 digits, 1884-2099)
        # and there's no year attribute yet, treat it as a year
        # Examples: "535-2013", "802.1AC-2016", "C37.41-2016"
        # AIEE established in 1884, so years range from 1884 to 2099
        # ONLY apply this when there are NO code_parts (meaning parser didn't capture parts separately)
        # This prevents breaking legitimate dual-published identifiers
        # Match ending with dash followed by 4 digits only (not dot, to preserve 802.1AC patterns)
        if code_str && !parsed[:year] && code_parts.empty? && (match = code_str.match(/^(.+)-(\d{4})$/))
          potential_year = match[2].to_i
          if potential_year.between?(1884, 2099)
            # This is a year - extract it
            code_str = match[1] # Remove year from code
            parsed[:year] = match[2] # Add to parsed for extraction below
          end
        end

        attributes[:code] = code_str

        # Extract year - check for edition_month parsed separately
        if parsed[:year]
          year_str = extract_value(parsed[:year])
          attributes[:year] = year_str
        end

        # Extract edition_month if parsed separately
        if parsed[:edition_month]
          attributes[:edition_month] = extract_value(parsed[:edition_month])
        end

        # Set type attribute for backward compatibility (after P extraction)
        # NOTE: "P" IS a type code that maps to ProjectDraftIdentifier via flavor module
        # Type can be: "Std", "No", "P" (project draft), etc.
        attributes[:type] = type_value if type_value

        # Lookup typed_stage from registry
        typed_stage_abbr = determine_stage_abbr(type_value, draft_status_value,
                                                parsed)
        if typed_stage_abbr
          attributes[:typed_stage] =
            Pubid::Ieee.locate_stage(typed_stage_abbr)
        end

        attributes[:draft_status] = draft_status_value

        # Optional attributes (excluding part/subpart since they're in code)
        extract_optional(parsed, attributes, :edition)
        extract_optional(parsed, attributes, :revision)

        # Month/day - always extract if present (but not if already extracted from year)
        unless attributes[:edition_month]
          extract_optional(parsed, attributes,
                           :month)
        end
        extract_optional(parsed, attributes, :day)

        # Handle draft (can be complex)
        handle_draft(parsed, attributes)

        # Default draft version 1 when the type indicates a Draft but the
        # parser found no explicit version (issue #205). Real-world IEEE
        # drafts always have at least version 1; the missing suffix is a
        # source-data omission, not an undrafted document.
        apply_default_draft_version(attributes, type_value)

        # Handle corrigendum
        handle_corrigendum(parsed, attributes)

        # Handle amendment
        handle_amendment(parsed, attributes)

        # Handle interpretation (already extracted as boolean)
        # attributes[:interpretation] = true if parsed[:interpretation]

        # Handle conformance
        handle_conformance(parsed, attributes)

        # Handle ASHRAE copub
        handle_ashrae_copub(parsed, attributes)

        # Handle IEEE crossref
        handle_ieee_crossref(parsed, attributes)

        # Handle reaffirmed
        handle_reaffirmed(parsed, attributes)

        # Handle additional parameters
        handle_parameters(parsed, attributes)

        # Book nickname
        if parsed[:nickname]
          attributes[:nickname] = extract_value(parsed[:nickname])
        end

        # Interpretation
        attributes[:interpretation] = true if parsed[:interpretation]

        # Redline
        attributes[:redline] = true if parsed[:redline]

        attributes
      end

      # Determine stage abbreviation for TYPED_STAGE lookup
      # @param type_value [String] the type value (e.g., "Std", "P")
      # @param draft_status_value [String] the draft status (e.g., "Unapproved")
      # @param parsed [Hash] the full parsed data
      # @return [String, nil] the abbreviation to use for stage lookup
      def determine_stage_abbr(type_value, _draft_status_value, parsed)
        # Check for specific draft notation (D1, D2, etc.)
        if parsed[:draft]
          draft_data = parsed[:draft]
          if draft_data.is_a?(Array)
            draft_data = draft_data.inject({}) do |r, e|
              r.merge(e)
            end
          end

          if draft_data.is_a?(Hash) && draft_data[:draft_version]
            dv = draft_data[:draft_version]
            version = if dv.is_a?(Array)
                        dv.map do |v|
                          extract_value(v)
                        end.join
                      else
                        extract_value(dv)
                      end

            # Construct draft notation like "D1", "D2", etc.
            if version
              draft_abbr = "D#{version}"
              # Check if this specific draft stage is in registry
              stage = Pubid::Ieee.locate_stage(draft_abbr)
              return draft_abbr if stage&.abbr&.include?(draft_abbr)
            end
          end
        end

        # Check type value for known abbreviations
        if type_value
          # Remove leading "P" and check if it exists in registry
          if type_value.start_with?("P")
            # Could be just "P" prefix or "P" as type indicator
            # If the type is literally "P" followed by numbers, it's a project identifier
            # Return "P" to get the generic project typed_stage
            return "P"
          elsif type_value == "Std"
            return "Std"
          elsif type_value.match?(/^No\.?$/)
            return type_value
          end
        end

        # Default to "Std" for published standards
        "Std"
      end

      # Extract a simple value from parsed data
      # @param value [Object] the value to extract
      # @return [String, nil] the extracted string value
      def extract_value(value)
        return nil if value.nil?
        return nil if value.is_a?(Array) && value.empty?

        if value.is_a?(Array)
          joined = value.join
          return joined.length.positive? ? joined : nil
        end

        str_value = value.to_s.strip
        str_value.length.positive? ? str_value : nil
      end

      # Extract optional attribute if present
      def extract_optional(parsed, attributes, key)
        value = extract_value(parsed[key])
        attributes[key] = value if value
      end

      # Default draft version to "1" when the identifier type indicates a
      # Draft but the parser found no explicit version (issue #205).
      def apply_default_draft_version(attributes, type_value)
        return if attributes[:draft] || attributes[:draft_obj]
        return unless type_value.to_s == "Draft Std"

        attributes[:draft] = "D1"
        # Carry the identifier's year into the draft object so the renderer
        # doesn't drop it (the renderer suppresses the `-YYYY` suffix when
        # a draft is attached, expecting the year to live inside /D...).
        attributes[:draft_obj] =
          Components::Draft.new(version: "1", year: attributes[:year])
      end

      # Handle draft information
      def handle_draft(parsed, attributes)
        draft_data = parsed[:draft] || parsed[:digit_draft]
        return unless draft_data

        # Draft can be an array of hash elements or a single hash
        if draft_data.is_a?(Array)
          # Merge all elements in the array
          merged = draft_data.inject({}) { |result, elem| result.merge(elem) }
          draft_data = merged
        end

        # Extract draft version and revision
        version = nil
        revision = nil
        month = nil
        year = nil
        day = nil
        comma_before_month = false

        if draft_data.is_a?(Hash)
          if draft_data[:draft_version]
            dv = draft_data[:draft_version]
            version = if dv.is_a?(Array)
                        dv.map { |v| extract_value(v) }.join
                      else
                        extract_value(dv)
                      end
          end

          revision = extract_value(draft_data[:revision]) if draft_data[:revision]

          # Extract date information from draft data
          month_slice = draft_data[:month]
          month = extract_value(month_slice) if month_slice
          year = extract_value(draft_data[:year]) if draft_data[:year]
          day = extract_value(draft_data[:day]) if draft_data[:day]

          # Detect comma before month and space before draft by checking the original input
          if original_input
            if month
              # Look for ", Month" pattern in the original input
              comma_before_month = original_input.match?(/,\s+#{Regexp.escape(month)}/i)
            end

            # Check if there's a space before /D in the original input
            if version && original_input.match?(/\s+\/D#{Regexp.escape(version)}/i)
              attributes[:space_before_draft] = true
            end
          end
        else
          version = extract_value(draft_data)
        end

        # Create Draft component object if we have version info
        if version
          draft_obj = Components::Draft.new(
            version: version,
            revision: revision,
            month: month,
            year: year,
            day: day,
          )
          draft_obj.comma_before_month = comma_before_month
          attributes[:draft_obj] = draft_obj
          attributes[:draft] = draft_obj.to_s
        end
      end

      # Handle corrigendum information
      def handle_corrigendum(parsed, attributes)
        if parsed[:corrigendum].is_a?(Hash)
          cor_data = parsed[:corrigendum]
          attributes[:cor_number] = extract_value(cor_data[:cor_number])
          if cor_data[:cor_year]
            attributes[:cor_year] =
              extract_value(cor_data[:cor_year])
          end
        elsif parsed[:corrigendum]
          attributes[:corrigendum] = extract_value(parsed[:corrigendum])
        end
      end

      # Handle amendment information
      def handle_amendment(parsed, attributes)
        if parsed[:amendment].is_a?(Hash)
          amd_data = parsed[:amendment]
          attributes[:amd_number] = extract_value(amd_data[:amd_number])
          if amd_data[:amd_year]
            attributes[:amd_year] =
              extract_value(amd_data[:amd_year])
          end
        elsif parsed[:amendment]
          attributes[:amendment] = extract_value(parsed[:amendment])
        end
      end

      # Handle reaffirmed information
      def handle_reaffirmed(parsed, attributes)
        if parsed[:reaffirmed].is_a?(Hash)
          reaf_data = parsed[:reaffirmed]
          attributes[:reaffirmed] = extract_value(reaf_data[:year])
        elsif parsed[:reaffirmed]
          attributes[:reaffirmed] = extract_value(parsed[:reaffirmed])
        end
      end

      # Handle conformance document information
      def handle_conformance(parsed, attributes)
        if parsed[:conformance].is_a?(Hash)
          conf_data = parsed[:conformance]
          attributes[:conf_number] = extract_value(conf_data[:conf_number])
          if conf_data[:conf_year]
            attributes[:conf_year] = extract_value(conf_data[:conf_year])
          end
        elsif parsed[:conformance]
          attributes[:conformance] = extract_value(parsed[:conformance])
        end
      end

      # Handle ASHRAE joint publication information
      def handle_ashrae_copub(parsed, attributes)
        if parsed[:ashrae_copub].is_a?(Hash)
          ashrae_data = parsed[:ashrae_copub]
          attributes[:ashrae_number] =
            extract_value(ashrae_data[:ashrae_number])
          if ashrae_data[:ashrae_year]
            attributes[:ashrae_year] = extract_value(ashrae_data[:ashrae_year])
          end
        elsif parsed[:ashrae_copub]
          attributes[:ashrae_copub] = extract_value(parsed[:ashrae_copub])
        end
      end

      # Handle IEEE cross-reference information
      def handle_ieee_crossref(parsed, attributes)
        if parsed[:ieee_crossref].is_a?(Hash)
          parsed[:ieee_crossref]
          # Extract the cross-reference string (e.g., "C62.22.1-1996")
          # Store it for rendering
          attributes[:crossref] =
            "/C#{extract_value(crossref).to_s.sub(/^\//, '')}"
        elsif parsed[:ieee_crossref]
          attributes[:crossref] = extract_value(parsed[:ieee_crossref])
        end
      end

      # Handle additional parameters
      def handle_parameters(parsed, attributes)
        if parsed[:parameters].is_a?(Hash)
          param_data = parsed[:parameters]

          # Handle parenthetical content (for multi-part adoptions like "ANSI Y32.21-1976, NCTA 006-0975")
          if param_data[:parenthetical_content]
            attributes[:parenthetical_content] =
              extract_value(param_data[:parenthetical_content])
          end

          if param_data[:revision_of]
            attributes[:revision_of] =
              extract_value(param_data[:revision_of])
          end
          if param_data[:amendment_to]
            attributes[:amendment_to] =
              extract_value(param_data[:amendment_to])
          end
          if param_data[:adoption]
            attributes[:adoption] =
              extract_value(param_data[:adoption])
          end
          if param_data[:note]
            attributes[:note] =
              extract_value(param_data[:note])
          end
        end
      end

      # Build relationships from parsed relationship clause (Pattern 4)
      # @param parsed_hash [Hash] the parsed data containing relationship information
      # @return [Array<Components::Relationship>] array of Relationship objects
      def build_relationships(parsed_hash)
        return [] unless parsed_hash[:relationship_type] || parsed_hash[:relationship_clause]

        relationships = []

        # Main relationship
        if parsed_hash[:relationship_type]
          rel_type = extract_relationship_type(parsed_hash[:relationship_type])
          related = parse_identifier_list(parsed_hash[:related_ids])

          # Handle "as amended by" clause
          amendments = nil
          approved_flag = false

          if parsed_hash[:amendments]
            # Check if it's the "and its approved amendments" flag
            if parsed_hash[:amendments].is_a?(Hash) && parsed_hash[:amendments][:approved_amendments]
              approved_flag = true
            else
              amendments = parse_identifier_list(parsed_hash[:amendments])
            end
          end

          relationships << Components::Relationship.new(
            relationship_type: rel_type,
            related_identifiers: related,
            intermediate_amendments: amendments,
            approved_amendments_flag: approved_flag,
          )
        end

        # Additional relationships (separated by " / ")
        if parsed_hash[:additional_rels]
          additional = parsed_hash[:additional_rels]
          additional = [additional] unless additional.is_a?(Array)

          additional.each do |rel_data|
            rel_type = extract_relationship_type(rel_data[:relationship_type])
            related = parse_identifier_list(rel_data[:related_ids])

            # Handle "as amended by" clause for additional relationships
            amendments = nil
            approved_flag = false

            if rel_data[:amendments]
              if rel_data[:amendments].is_a?(Hash) && rel_data[:amendments][:approved_amendments]
                approved_flag = true
              else
                amendments = parse_identifier_list(rel_data[:amendments])
              end
            end

            relationships << Components::Relationship.new(
              relationship_type: rel_type,
              related_identifiers: related,
              intermediate_amendments: amendments,
              approved_amendments_flag: approved_flag,
            )
          end
        end

        relationships
      end

      # Extract relationship type from parsed hash
      # @param type_hash [Hash] hash with relationship type key
      # @return [String] the relationship type constant name
      def extract_relationship_type(type_hash)
        return nil unless type_hash.is_a?(Hash)

        # type_hash has key like :revision_of, :amendment_to, etc.
        type_hash.keys.first.to_s
      end

      # Parse a list of identifier strings into identifier objects
      # @param list_data [Hash, Array, nil] the parsed identifier list data
      # @return [Array<Identifier>] array of parsed identifier objects
      def parse_identifier_list(list_data)
        return [] unless list_data

        # Extract identifier strings from parsed data
        id_strings = extract_identifier_strings(list_data)

        # Recursively parse each identifier string
        id_strings.map do |id_str|
          # Use Identifier.parse for recursive parsing
          Identifier.parse(id_str)
        rescue Parslet::ParseFailed
          # If parsing fails, create minimal identifier with just the string
          # This maintains graceful degradation
          Identifier.new(parenthetical_content: id_str)
        end
      end

      # Extract identifier strings from parsed list data
      # @param list_data [Hash, Array] the parsed list data
      # @return [Array<String>] array of identifier strings
      def extract_identifier_strings(list_data)
        if list_data.is_a?(Array)
          # Array of id hashes: [{id: "..."}, {id: "..."}]
          list_data.map { |item| item[:id].to_s.strip }
        elsif list_data.is_a?(Hash) && list_data[:id]
          # Single id hash: {id: "..."}
          [list_data[:id].to_s.strip]
        else
          []
        end
      end

      # Build combined AIEE identifier from "and"-separated identifiers
      # @param parsed [Hash] parsed combined AIEE data
      # @return [Identifiers::CombinedAiee] combined AIEE identifier
      def build_combined_aiee(parsed)
        # Build each AIEE identifier using AIEE builder
        aiee_builder = Aiee::Builder.new
        first_id = aiee_builder.build(parsed[:first_aiee])
        second_id = aiee_builder.build(parsed[:second_aiee])

        # Create a simple combined identifier (reuse DualPublished pattern)
        Identifiers::DualPublished.new(
          first_identifier: first_id,
          second_identifier: second_id,
          separator: " and ",
        )
      end
    end
  end
end
