# frozen_string_literal: true

module Pubid
  module CenCenelec
    class Builder < Pubid::Builder::Base
      def self.build(parsed_data)
        new.build(parsed_data)
      end

      def build(data)
        data = flatten_array(data) if data.is_a?(Array)

        # Store data for access in cast method
        @data = data

        # Check if this is a fragment identifier (AMD + FRAG)
        if data[:fragment_number]
          return build_fragment_identifier(data)
        end

        # "TR" is a CEN or CLC technical report ("CEN/TR", "CLC/TR") — the
        # EN publisher never carries it (pubid ruling 2026-10-13).
        if data[:type].to_s == "TR" && %w[EN].include?(data[:publisher].to_s)
          raise Pubid::Errors::ParseError,
                "\"EN\" cannot be \"TR\": a technical report is \"CEN/TR\" or \"CLC/TR\""
        end

        # Every base document (an adopted norm, an ENV adoption, a plain
        # identifier) goes through the same supplement wrapping. The adopted
        # branches used to return early, so "CEN ISO/TS 21003-7:2008/A1:2010"
        # lost its "/A1:2010".
        base = build_base_document(data)

        # A slash separator makes a standalone amendment/corrigendum; a plus
        # separator makes a consolidated (bundled) identifier.
        if has_slash_supplements?(data)
          build_standalone_supplement(base, data)
        elsif (supplements_data = extract_supplements(data)).any?
          wrap_with_consolidated(base, supplements_data)
        else
          base
        end
      end

      private

      # The document that the supplements of +data+ apply to, or the whole
      # identifier when there are no supplements.
      def build_base_document(data)
        # Check if this is an adopted identifier (EN ISO, EN IEC, etc.)
        if data[:adopted_string]
          # Special case: ENV can adopt ISO/IEC standards
          if data[:publisher]&.to_s == "ENV"
            return build_env_adopted_identifier(data)
          end

          return build_adopted_identifier(data)
        end

        # Implicit adoption: when an EN has no explicit "IEC" prefix but
        # the number falls in the IEC range (60000-79999), treat it as an
        # adoption of the corresponding IEC standard. The lower ISO-only
        # range (1-59999) is intentionally NOT mapped here — too many
        # existing CEN publications (EN Guide N, EN N as a real CEN-assigned
        # number) would change type. Callers who want explicit adoption
        # can still write "EN ISO 12345".
        # (https://github.com/pubid/pubid/issues/249)
        # Skip when parts are present — they would be lost when we rebuild
        # the identifier from just the base number — and when supplements
        # are present, which the adoption used to drop the same way.
        if data[:publisher]&.to_s == "EN" && data[:parts].to_a.empty? &&
            !supplements?(data) &&
            (adopted = build_implicit_adoption(data))
          return adopted
        end

        # Determine identifier class using the module's lookup helpers
        base_data = data.except(:supplements)
        identifier = locate_identifier_klass(base_data).new
        assign_attributes(identifier, base_data)
        identifier
      end

      def supplements?(data)
        has_slash_supplements?(data) || extract_supplements(data).any?
      end

      # A number or month the grammar captured as an empty string is stored
      # as nil: `to_hash` drops an empty string, so from_hash would give nil
      # and the two identifiers would not be `==`.
      def present_string(value)
        str = value&.to_s
        str unless str.nil? || str.empty?
      end

      def build_fragment_identifier(data)
        # Build base identifier first (without amendment/fragment)
        base_data = data.dup
        base_data.delete(:amendment_number)
        base_data.delete(:fragment_number)

        base = locate_identifier_klass(base_data).new
        assign_attributes(base, base_data)

        # Build Amendment identifier wrapping the base. The compact
        # fragment spelling can carry the amendment's own year
        # (EN 60038/A1:2009 FRAG2); the AMD-keyword spelling cannot.
        amendment = Identifiers::Amendment.new(
          base: base,
          number: data[:amendment_number].to_s,
          year: data[:amendment_year]&.to_s,
        )

        # Build Fragment wrapping the amendment
        Identifiers::Fragment.new(
          base: amendment,
          number: data[:fragment_number].to_s,
        )
      end

      def locate_identifier_klass(parsed_hash)
        # Special case: Use adopted_european_norm for adopted identifiers
        return Identifiers::AdoptedEuropeanNorm if parsed_hash[:adopted_string]

        # Check if publisher is actually a type code (CWA, HD, ES, CR, ENV act as publisher)
        publisher_str = parsed_hash[:publisher].to_s
        if CenCenelec::PUBLISHER_TYPES.include?(publisher_str)
          typed_stage = CenCenelec.locate_stage(publisher_str)
          if (klass = CenCenelec.locate_type(typed_stage.type_code))
            return klass
          end
        end

        # Use type or stage to determine class via the module's registry
        type_or_stage = parsed_hash[:type_with_stage] || parsed_hash[:type] || parsed_hash[:stage] || ""
        typed_stage = CenCenelec.locate_stage(type_or_stage) || CenCenelec::DEFAULT_TYPED_STAGE
        CenCenelec.locate_type(typed_stage.type_code) || Identifiers::EuropeanNorm
      end

      def cast(type, value)
        case type
        when :type_with_stage
          # Lookup from register
          typed_stage = CenCenelec.locate_stage(value.to_s) || CenCenelec::DEFAULT_TYPED_STAGE
          {
            stage: typed_stage.to_stage,
            type: typed_stage.to_type,
            typed_stage: typed_stage,
          }

        when :publisher
          Components::Publisher.new(body: value.to_s)

        when :copublisher
          # Map singular :copublisher to :copublishers array
          { copublishers: [Components::Publisher.new(body: value.to_s)] }

        when :copublishers
          # Handle array of copublishers
          Array(value).map do |v|
            Components::Publisher.new(body: v[:copublisher].to_s)
          end

        when :number
          value.to_s

        when :parts
          # Extract first part, preserve full multi-level part string
          parts_array = Array(value)
          if parts_array.any?
            # Get the part string - it may contain multiple dashes like "5-1-1"
            part_str = parts_array.first[:part].to_s

            # Store the full part value for multi-level parts
            { part: part_str }
          end

        when :part
          value[:part].to_s if value.is_a?(Hash)

        when :version
          value.to_s unless value.to_s.empty?

        when :year, :date
          # Check if month is present in the data and include it
          month_val = @data[:month]&.to_s
          date_attrs = { year: value.to_s }
          date_attrs[:month] = month_val if month_val && !month_val.empty?
          { date: Components::Date.new(**date_attrs) }

        when :month
          # Month is handled together with year, so skip it here
          nil

        when :type
          Components::Type.new(abbr: value.to_s)

        when :stage
          # Lookup stage in TYPED_STAGES register
          typed_stage = CenCenelec.locate_stage(value.to_s) || CenCenelec::DEFAULT_TYPED_STAGE
          {
            stage: typed_stage.to_stage,
            typed_stage: typed_stage,
          }

        when :edition
          value.to_s

        when :adopted_string
          # Don't cast here, handled in build_adopted_identifier
          nil

        when :supplements
          # Handled separately by extract_supplements
          nil

        else
          value
        end
      end

      def build_adopted_identifier(data)
        # Parse the adopted identifier string with appropriate flavor
        adopted_str = data[:adopted_string]&.to_s&.strip
        return nil unless adopted_str && !adopted_str.empty?

        adopted_id = if adopted_str.start_with?("ISO/IEC") || adopted_str.include?("ISO/IEC")
                       Pubid::Iso.parse(adopted_str)
                     elsif adopted_str.start_with?("ISO")
                       Pubid::Iso.parse(adopted_str)
                     elsif adopted_str.start_with?("IEC")
                       Pubid::Iec.parse(adopted_str)
                     elsif adopted_str.start_with?("CISPR")
                       # CISPR might need specific handling
                       nil
                     end

        # The publisher is a Components::Publisher (EN is the default for
        # adoptions); a second publisher ("CEN/CLC") is a copublisher.
        copublishers = if data[:copublishers]
                         Array(data[:copublishers]).map do |copub|
                           copub[:copublisher].to_s
                         end
                       elsif data[:copublisher]
                         [data[:copublisher].to_s]
                       else
                         []
                       end

        attrs = { adopted: adopted_id }
        # "prEN ISO 1234:2020": the draft stage is on the CEN adoption. The
        # parser captures it as type_with_stage and not as a publisher, and
        # it used to be dropped here, so the identifier rendered as "EN ISO".
        if data[:type_with_stage]
          attrs.merge!(cast(:type_with_stage, data[:type_with_stage]))
        end
        if data[:publisher]
          attrs[:publisher] =
            Components::Publisher.new(body: data[:publisher].to_s)
        end
        # Only when present: an empty collection would not survive to_hash,
        # and from_hash would then give nil where the parse gave [].
        unless copublishers.empty?
          attrs[:copublishers] = copublishers.map do |body|
            Components::Publisher.new(body: body)
          end
        end

        Identifiers::AdoptedEuropeanNorm.new(**attrs)
      end

      # Implicit adoption by number range. Returns an AdoptedEuropeanNorm
      # wrapping the IEC identifier that the EN number implies, or nil if the
      # number does not fall in the IEC range. Limited to IEC range only —
      # see the call site comment for why the ISO range is excluded.
      def build_implicit_adoption(data)
        number = data[:number].to_s
        num_str = number.to_s.strip
        return nil unless num_str.match?(/\A\d{1,6}\z/)

        num = num_str.to_i
        return nil unless (60_000..79_999).cover?(num)

        # The publisher is the "EN" default.
        Identifiers::AdoptedEuropeanNorm.new(
          adopted: Pubid::Iec.parse("IEC #{num_str}"),
        )
      end

      def build_env_adopted_identifier(data)
        # Parse the adopted identifier string
        adopted_str = data[:adopted_string]&.to_s&.strip
        return nil unless adopted_str && !adopted_str.empty?

        adopted_id = if adopted_str.start_with?("ISO/IEC") || adopted_str.include?("ISO/IEC")
                       Pubid::Iso.parse(adopted_str)
                     elsif adopted_str.start_with?("ISO")
                       Pubid::Iso.parse(adopted_str)
                     elsif adopted_str.start_with?("IEC")
                       Pubid::Iec.parse(adopted_str)
                     end

        # The publisher is ENV, as for a plain "ENV 1613:1995"; the
        # SingleIdentifier default is EN.
        Identifiers::EuropeanPrestandard.new(
          publisher: Components::Publisher.new(body: "ENV"),
          adopted: adopted_id,
        )
      end

      # The members after the first carry no `base`: the consolidated
      # identifier holds the base document once, as its first member. With a
      # `base` in each member, `to_hash` wrote the base again for every "+".
      def wrap_with_consolidated(base, supplements_data)
        supplement_ids = supplements_data.map do |supp|
          if supp[:type] == :amendment
            Identifiers::Amendment.new(
              number: present_string(supp[:number]),
              year: present_string(supp[:year]),
            )
          else
            Identifiers::Corrigendum.new(
              number: present_string(supp[:number]),
              year: present_string(supp[:year]),
              month: present_string(supp[:month]),
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

        # Only extract supplements with PLUS separator (bundled)
        # Slash-separated supplements are standalone identifiers, not bundled
        supps_array.select do |s|
          supp_data = s.is_a?(Hash) && s[:supplement] ? s[:supplement] : s
          # Only include if it has plus separator
          supp_data[:amd_sep_plus]
        end.map do |s|
          supp_data = s.is_a?(Hash) && s[:supplement] ? s[:supplement] : s

          # Extract year and month if present
          year_val = (supp_data[:amd_year] || supp_data[:year])&.to_s
          month_val = supp_data[:month]&.to_s

          {
            type: supp_data[:amd_number] ? :amendment : :corrigendum,
            number: (supp_data[:amd_number] || supp_data[:cor_number])&.to_s,
            year: year_val,
            month: month_val,
          }
        end
      end

      def has_slash_supplements?(data)
        return false unless data[:supplements]

        supps_array = data[:supplements]
        return false if supps_array.empty?

        # Check if any supplement has slash separator
        supps_array.any? do |s|
          supp_data = s.is_a?(Hash) && s[:supplement] ? s[:supplement] : s
          supp_data[:amd_sep_slash]
        end
      end

      def build_standalone_supplement(base, data)
        # Get the first supplement (slash means only one supplement)
        supp_array = data[:supplements]
        supp_data = supp_array.first
        supp_data = supp_data[:supplement] if supp_data.is_a?(Hash) && supp_data[:supplement]

        # Build appropriate supplement identifier
        if supp_data[:amd_number]
          Identifiers::Amendment.new(
            base: base,
            number: supp_data[:amd_number].to_s,
            year: present_string(supp_data[:amd_year]),
          )
        else
          Identifiers::Corrigendum.new(
            base: base,
            number: present_string(supp_data[:cor_number]),
            year: present_string(supp_data[:year]),
            month: present_string(supp_data[:month]),
          )
        end
      end
    end
  end
end

Pubid::CenCenelec::Builder.prepend(Pubid::Builder::AllPartsWrap)
