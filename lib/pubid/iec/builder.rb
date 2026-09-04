# frozen_string_literal: true

module Pubid
  module Iec
    class Builder < Pubid::Builder::Base
      def locate_identifier_klass(parsed_hash)
        # Check for working programme
        if parsed_hash[:wp_stage]
          return Identifiers::WorkingDocument
        end

        # Check for technical group (committee identifier, no document number)
        if parsed_hash[:technical_committee] && !parsed_hash[:wd_number]
          return Identifiers::TechnicalGroup
        end

        # Check for working document
        if parsed_hash[:technical_committee] && parsed_hash[:wd_number]
          return Identifiers::WorkingDocument
        end

        # Check the `:type_with_stage` to determine the identifier class
        # :type_with_stage will be nil if it is an IS.
        typed_stage = locate_typed_stage(parsed_hash[:type_with_stage])

        Pubid::Iec.locate_type(typed_stage.type_code) ||
          raise(ArgumentError, "Unknown type code: #{typed_stage.type_code}")
      end

      def build(parsed_hash)
        # Handle sheet_supplement_identifier pattern:
        # {base: {...}, sheet_number: ..., sheet_year: ..., type_with_stage: "COR", number_with_part: "1", date: "1995"}
        # This is a Corrigendum/Amendment wrapping a SheetIdentifier
        if parsed_hash[:base] && (parsed_hash[:sheet_number] || parsed_hash[:sheet_year]) && parsed_hash[:type_with_stage]
          # Extract sheet info first
          sheet_number = parsed_hash.delete(:sheet_number)
          sheet_year = parsed_hash.delete(:sheet_year)

          # Build the base identifier (IEC 60695-2-1 with /1:1994 -> SheetIdentifier)
          base_parsed = parsed_hash[:base].dup
          base_parsed[:sheet_number] = sheet_number
          base_parsed[:sheet_year] = sheet_year if sheet_year
          sheet_id = wrap_with_sheet(build(base_parsed), sheet_number,
                                     sheet_year)

          # Now build the supplement on top of the sheet
          # We need to preserve the supplement data and create a wrapper
          supplement_type = parsed_hash.delete(:type_with_stage)
          supplement_number = parsed_hash.delete(:number_with_part)
          supplement_date = parsed_hash.delete(:date)
          supplement_edition = parsed_hash.delete(:edition)

          # Locate the supplement identifier class
          typed_stage = locate_typed_stage(supplement_type)
          identifier_class = Pubid::Iec.locate_type(typed_stage.type_code) ||
            raise(ArgumentError, "Unknown type code: #{typed_stage.type_code}")

          # Create the supplement identifier
          supplement = identifier_class.new
          supp_attrs = identifier_class.attributes
          if supp_attrs.key?(:number)
            supplement.number = Components::Code.new(value: supplement_number.to_s)
          end
          if supplement_date && supp_attrs.key?(:date)
            supplement.date = cast(:date, supplement_date)
          end
          if supplement_edition && supp_attrs.key?(:edition)
            supplement.edition = cast(:edition, supplement_edition)
          end
          supplement.typed_stage = typed_stage

          # Wrap the sheet with the supplement
          return wrap_with_supplement(sheet_id, supplement)
        end

        # Handle sheet_identifier pattern: {base: {...}, sheet_number: ..., sheet_year: ...}
        if parsed_hash[:base] && (parsed_hash[:sheet_number] || parsed_hash[:sheet_year])
          # Build the base identifier first
          base_id = build(parsed_hash[:base])
          # Wrap with SheetIdentifier
          sheet_number = parsed_hash.delete(:sheet_number)
          sheet_year = parsed_hash.delete(:sheet_year)
          return wrap_with_sheet(base_id, sheet_number, sheet_year)
        end

        # Extract FRAG/FRAGC indicator if present
        frag_abbrs = Pubid::Iec::Identifiers::FragmentIdentifier::TYPED_STAGES
          .flat_map(&:abbr)
        is_fragment = frag_abbrs.include?(parsed_hash[:type_with_stage]) ||
          parsed_hash[:type_with_stage] == "FRAGC"
        fragment_typed_stage = nil
        fragment_number = nil
        fragment_edition = nil

        if is_fragment
          # For FRAG typed stages, look up the fragment's own typed stage
          fragment_typed_stage = Pubid::Iec.locate_stage(parsed_hash[:type_with_stage])

          # FRAGC is a rendering notation, not a typed stage abbreviation;
          # fall back to the canonical "FRAG" typed stage
          fragment_typed_stage ||= Pubid::Iec.locate_stage("FRAG")

          # For FRAG/FRAGC, we need to build the base Amendment/Corrigendum
          # then wrap it with FragmentIdentifier
          if parsed_hash[:number_with_part]
            fragment_number = parsed_hash[:number_with_part].to_s
          end

          # Extract edition for fragment
          fragment_edition = parsed_hash.delete(:edition)

          # Build the base identifier (Amendment/Corrigendum) directly
          if parsed_hash[:base]
            base_id = build(parsed_hash[:base])
            return wrap_with_fragment(base_id, fragment_number,
                                      fragment_edition, fragment_typed_stage)
          end
        end

        # Check for TRF with CISPR - build embedded identifier
        trf_org = parsed_hash.delete(:trf_org)
        if trf_org && parsed_hash[:number_with_part]
          # Build CISPR identifier without year
          cispr_number = parsed_hash.delete(:number_with_part)
          cispr_id = Identifiers::InternationalStandard.new(
            publisher: Components::Publisher.new(body: "CISPR"),
          )
          # Set number via cast
          number_components = cast(:number_with_part, cispr_number)
          attrs = cispr_id.class.attributes
          number_components.each_pair do |k, v|
            cispr_id.public_send("#{k}=", v) if attrs.key?(k.to_sym)
          end
          parsed_hash[:cispr_identifier] = cispr_id
        end

        # Extract and store wrapper data before building
        consolidated_supplements_data = parsed_hash.delete(:consolidated_supplements)
        vap_suffix_data = parsed_hash.delete(:vap_suffix)
        # Note: sheet_number and sheet_year are now handled in sheet_identifier check above
        fragment_type_data = parsed_hash.delete(:fragment_type)
        fragment_number_data = parsed_hash.delete(:fragment_number)

        # Instantiate the identifier based on the typed stage
        identifier = locate_identifier_klass(parsed_hash).new

        # For French GUIDE entries: "Guide IEC 51:1999"
        if type_with_stage_fr = parsed_hash.delete(:type_with_stage_fr)
          parsed_hash[:type_with_stage] = type_with_stage_fr
        end

        assign_attributes(identifier, parsed_hash)

        # Detect rendering style from parsed abbreviation.
        #
        # UNREACHABLE TODAY: no IEC identifier class declares a
        # `rendering_style` attribute, so this whole block never runs. Its
        # `original_abbr` reads below are therefore NOT a live consumer of that
        # field — which is why `original_abbr` can be left nil on both the parse
        # and the from_hash paths (see Identifier.published_typed_stage). The
        # long-vs-short stage spelling is already collapsed: "…/Amd 1:2017"
        # renders back as "…/AMD1:2017". Do not treat this as working code.
        if identifier.class.attributes.key?(:rendering_style) && identifier.typed_stage
          ts = identifier.typed_stage

          # Detect IEC format from parsed abbreviation
          # IEC uses space to indicate long form: "Amd 1", "Cor 1"
          # No space indicates short form: "AMD1", "COR1"
          stage_format_long = if ts.long_abbr && ts.original_abbr&.include?(" ")
                                true # Long form has space: "Amd 1", "Cor 1"
                              elsif ts.short_abbr && ts.original_abbr && !ts.original_abbr.include?(" ")
                                false  # Short form: "AMD1", "COR1", "CDV", "FDIS"
                              else
                                false  # Default to short/canonical
                              end

          # Detect language code format from parsed languages
          langs = if identifier.class.attributes.key?(:languages)
                    identifier.languages
                  end
          with_language_code = if langs&.any?
                                 # Check if original_code was single-char (E, F, R, A, S, D)
                                 first_lang = langs.first
                                 if first_lang.is_a?(::Pubid::Components::Language) && first_lang.original_code && first_lang.original_code.length == 1
                                   :single
                                 else
                                   :iso # 2-char codes (en, fr, ru, ar, es, de)
                                 end
                               else
                                 :none
                               end

          # with_date is always true for base identifiers (show the date if present)
          # Only supplements might have undated references
          with_date = true

          # Create custom rendering style based on parsed format
          identifier.rendering_style = RenderingStyle.new(
            with_language_code: with_language_code,
            stage_format_long: stage_format_long,
            with_date: with_date,
          )
        end

        # After building base identifier, apply wrappers
        if fragment_type_data && fragment_number_data
          frag_ts = Pubid::Iec.locate_stage("FRAG")
          identifier = wrap_with_fragment(identifier, fragment_number_data.to_s,
                                          nil, frag_ts)
        end
        # Note: sheet wrapping is now handled earlier in build method for sheet_identifier pattern
        if consolidated_supplements_data
          identifier = wrap_with_consolidated(identifier,
                                              consolidated_supplements_data)
        end
        if vap_suffix_data
          identifier = wrap_with_vap(identifier,
                                     vap_suffix_data)
        end

        identifier
      end

      def handle_key(identifier, key, value)
        if key == :joint_identifier
          identifier.additional_identifiers ||= []
          identifier.additional_identifiers << value
          true
        else
          false
        end
      end

      # The IEC builder's own `build` method drives identifier construction
      # (it locates the right class per parsed hash), so the parent class's
      # `@identifier_class` slot is never read. Provide a placeholder so
      # `Builder.new` doesn't fail with NotImplementedError.
      def default_identifier_class
        Identifiers::InternationalStandard
      end

      # Look up a typed stage by abbreviation via the self-describing
      # `Pubid::Iec` module instead of an injected scheme instance.
      def locate_typed_stage(typed_stage_string)
        typed_stage_string = "" if typed_stage_string.nil?
        Pubid::Iec.locate_stage(typed_stage_string) ||
          raise(ArgumentError, "Unknown type abbreviation: '#{typed_stage_string}'")
      end

      # Wrap identifier with FragmentIdentifier for /FRAGN notation
      def wrap_with_fragment(base, fragment_number,
      edition_data = nil, typed_stage = nil)
        fragment = Identifiers::FragmentIdentifier.new(
          base: base,
          fragment_number: fragment_number,
        )

        # Set typed stage if provided
        fragment.typed_stage = typed_stage if typed_stage

        # Set edition if provided
        if edition_data
          fragment.edition = cast(:edition, edition_data)
        end

        fragment
      end

      # Wrap identifier with SheetIdentifier for /N:YEAR notation
      def wrap_with_sheet(base, sheet_number, sheet_year)
        # Only pass year if it's present
        year_value = sheet_year&.to_s

        Identifiers::SheetIdentifier.new(
          base: base,
          sheet_number: sheet_number.to_s,
          year: year_value,
        )
      end

      # Wrap base identifier with supplement (Amendment/Corrigendum)
      def wrap_with_supplement(base, supplement)
        supplement.base = base
        supplement
      end

      # Wrap identifier with ConsolidatedIdentifier for +AMD chains
      def wrap_with_consolidated(base, supplements_data)
        supplements = supplements_data.filter_map do |supp|
          type = supp[:supplement_type].to_s
          number = supp[:supplement_number].to_s
          year = supp[:supplement_year]

          # Only create Date component if year is present
          date_component = year ? Pubid::Components::Date.new(year: year.to_s) : nil

          if type == "AMD"
            Identifiers::Amendment.new(
              number: Components::Code.new(value: number),
              date: date_component,
            )
          elsif type == "COR"
            Identifiers::Corrigendum.new(
              number: Components::Code.new(value: number),
              date: date_component,
            )
          end
        end

        Identifiers::ConsolidatedIdentifier.new(
          identifiers: [base] + supplements,
        )
      end

      # Wrap identifier with VapIdentifier for one or more VAP codes
      # (e.g. "CSV" or "EXV-CMV").
      def wrap_with_vap(base, vap_suffix_data)
        vap = vap_suffix_data.to_s.split("-")

        # Extract edition - need to go deep for ConsolidatedIdentifier
        edition = nil
        if base.is_a?(Identifiers::ConsolidatedIdentifier)
          # Edition is on the first identifier (base document)
          base_first = base.identifiers.first
          if base_first && base_first.class.attributes.key?(:edition)
            edition = base_first.edition
            base_first.edition = nil
          end
        elsif base.class.attributes.key?(:edition)
          edition = base.edition
          base.edition = nil
        end

        Identifiers::VapIdentifier.new(
          base: base,
          vap: vap,
          edition: edition,
        )
      end

      def convert_roman_to_integer(roman_numeral)
        return roman_numeral if roman_numeral.to_s.upcase == "X"

        super
      end

      # IEC normalizes em/en dashes to hyphens but preserves slashes and
      # spaces, which can be semantically meaningful in IEC identifiers.
      def normalize_number_with_part(value)
        value.to_s.tr(Parser::DASH_CHARS.join, "-")
      end

      def cast(type, value)
        case type
        when :base
          # If it has a base identifier, we need to build a supplement
          # We assume that the base identifier is already a valid Identifier object
          build(value)

        when :publisher
          Components::Publisher.new(body: value)

        when :copublishers
          if value.nil? || value.empty?
            nil
          else
            value.map do |copublisher|
              Components::Publisher.new(body: copublisher[:copublisher])
            end
          end

        when :technical_committee, :subcommittee, :wd_number, :wd_stage, :wd_language, :wp_stage, :wp_type
          # Working document/programme fields - just return as string
          value.to_s

        when :cispr_identifier
          # CISPR identifier object for TRF
          value

        when :number
          # Plain number for sub-org identifiers (CA, IECQ CS, IECQ OD)
          # Just return as Code component
          { number: Components::Code.new(value: value.to_s) }

        when :number_with_part
          # "60038" (no part)
          # or "60038-1" ('1' is part)
          # or "60038-1-2" ('1' is part, '2' is subpart)
          # or "29110-5-1-1" ('5' is part, '1-1' is subpart)
          parse_number_with_part(value, code_class: Components::Code)

        when :type_with_stage
          # "WD"
          # "TS"
          # "Guide"
          # FRAG typed stages are handled in the is_fragment check above

          iteration = value.to_s.match(/(\d+)$/)
          value = value.to_s.sub(iteration.to_s, "")
          typed_stage = locate_typed_stage(value || "")

          ## IMPORTANT!!
          # Always use TypedStage in an Identifier or separate Type and Stage.
          {
            stage: typed_stage.to_stage,
            type: typed_stage.to_type,
            typed_stage: typed_stage,
          }
        when :stage_iteration
          # "1" or "2"
          Pubid::Components::Iteration.new(number: value.to_s)

        when :date
          parse_date(value)

        when :undated_marker
          # ISO/IEC undated reference (e.g. "IEC 60050:--") — explicit
          # publication-date slot with no year; round-trips via date.render.
          { date: Pubid::Components::Date.new(undated: true) }

        when :edition
          # Coerce to String: the parsed value may be a Parslet::Slice, which
          # Edition.number (Type::Value) would store verbatim and serialize as a
          # !ruby/object:Parslet::Slice node — unloadable by the index reader's
          # YAML.safe_load(permitted_classes: [Symbol]).
          Pubid::Components::Edition.new(number: value&.to_s)

        when :sheet_number
          value.to_s

        when :sheet_year
          value.to_s

        when :languages
          parse_languages(value)

        when :all_parts
          # Set all_parts boolean attribute directly on identifier (matches ISO builder)
          true

        when :database
          # Database flag - return true if DB suffix present
          true

        # Handle joint identifiers with ISO
        when :joint_identifier
          case value[:publisher]
          when "ISO"
            Pubid::Iso.build_from_parse(value)
          end

        else
          raise ArgumentError, "Unknown parameter type: #{type}"
        end
      end
    end
  end
end
