# frozen_string_literal: true

module Pubid
  module Bsi
    # Human-readable renderer for BSI identifiers.
    #
    # Produces strings like:
    #   "BS 4592-0:2006+A1:2012"
    #   "BSI Flex 220 v1.0:2024"
    #   "NA+A1:2012 to BS EN 1090-2:2018"
    #
    # The renderer is registered as the +:human+ format in the BSI format
    # registry and invoked via +render(format: :human)+.
    #
    # For wrapper types (Consolidated, NationalAnnex, ExpertCommentary, etc.)
    # the renderer composes child identifiers. For simple identifiers it
    # dispatches to type-specific rendering methods.
    class Renderer < ::Pubid::Renderers::Base
      def render(context: nil, **opts)
        @context = context
        id = @id

        case id
        when Identifiers::AddendumDocument
          render_addendum_document(id, opts)
        when Identifiers::AdoptedEuropeanNorm
          render_adopted_european_norm(id)
        when Identifiers::AdoptedInternationalStandard
          render_adopted_international_standard(id)
        when Identifiers::AerospaceStandard
          render_aerospace_standard(id)
        when Identifiers::Amendment
          render_amendment(id)
        when Identifiers::BritishIndustrialPractice
          render_british_industrial_practice(id)
        when Identifiers::BundledIdentifier
          render_bundled_identifier(id)
        when Identifiers::CommitteeDocument
          render_committee_document(id)
        when Identifiers::ConsolidatedIdentifier
          render_consolidated_identifier(id, opts)
        when Identifiers::Corrigendum
          render_corrigendum(id)
        when Identifiers::DetailedSpecification
          render_detailed_specification(id)
        when Identifiers::Disc
          render_disc(id)
        when Identifiers::DraftDocument
          render_draft_document(id)
        when Identifiers::ElectronicBook
          render_electronic_book(id)
        when Identifiers::ExpertCommentary
          render_expert_commentary(id)
        when Identifiers::ExplanatorySupplement
          render_explanatory_supplement(id)
        when Identifiers::Flex
          render_flex(id)
        when Identifiers::Handbook
          render_handbook(id)
        when Identifiers::Index
          render_index(id)
        when Identifiers::Method
          render_method(id)
        when Identifiers::NationalAnnex
          render_national_annex(id)
        when Identifiers::PracticeGuide
          render_practice_guide(id)
        when Identifiers::PubliclyAvailableSpecification
          render_publicly_available_specification(id)
        when Identifiers::PublishedDocument
          render_published_document(id)
        when Identifiers::Section
          render_section(id)
        when Identifiers::Set
          render_set(id)
        when Identifiers::StandaloneAmendment
          render_standalone_amendment(id)
        when Identifiers::SupplementDocument
          render_supplement_document(id)
        when Identifiers::SupplementaryIndex
          render_supplementary_index(id)
        when Identifiers::TechnicalSpecification
          render_technical_specification(id)
        when Identifiers::TestMethod
          render_test_method(id)
        when Identifiers::ValueAddedPublication
          render_value_added_publication(id, opts)
        when SingleIdentifier
          render_single_identifier(id)
        else
          id.to_s
        end
      end

      private

      # ------------------------------------------------------------------
      # SingleIdentifier (base BSI identifier)
      # ------------------------------------------------------------------

      def render_single_identifier(id)
        parts = []

        parts << id.publisher.to_s if id.publisher
        if id.flex_prefix
          parts << id.flex_prefix
        elsif id.prefix
          parts << id.prefix.to_s
        end

        if id.number
          number_str = id.number.render(context: @context)

          if id.second_number
            second_val = id.second_number.render(context: @context)
            number_str += "/#{second_val}"
          end

          space_separated = id.space_separated_part
          if id.part
            part_val = id.part.render(context: @context)
            part_str = part_val.to_s.strip
            separator = space_separated ? " " : "-"
            number_str += "#{separator}#{part_str}"
          end
          if id.subpart
            subpart_val = id.subpart.render(context: @context)
            subpart_str = subpart_val.to_s.strip
            number_str += "-#{subpart_str}"
          end

          if id.iteration && !id.iteration.empty?
            number_str += "[#{id.iteration}]"
          end

          parts << number_str
        end

        result = parts.join(" ")

        if id.date
          year_val = id.date.render(context: @context)
          result += ":#{year_val}"
          result += "-#{format('%02d', id.month)}" if id.month
        end

        result += " v#{id.edition}" if id.edition

        if id.translation_lang
          result += " (#{id.translation_lang})"
        elsif id.translation_upper
          result += " (#{id.translation_upper})"
        end

        result
      end

      # ------------------------------------------------------------------
      # Wrapper types
      # ------------------------------------------------------------------

      def render_addendum_document(id, opts)
        result = id.base.to_s(**opts)

        base_has_year = id.base.to_s =~ /:(\d{4})$/

        sep = if id.separator == ":"
                ":"
              elsif base_has_year && id.base.to_s !~ /:\d{4}:/
                " "
              else
                id.separator
              end

        result += sep
        result += "Addendum"

        if id.addendum_type.empty?
          # No type prefix
        else
          result += " #{id.addendum_type}"
        end
        result += " "
        result += " "

        result += id.addendum_number.to_s
        result += ":#{id.addendum_year}" if id.addendum_year

        result
      end

      def render_adopted_european_norm(id)
        prefix = case id.publisher
                 when Components::Publisher
                   id.publisher.render(context: @context)
                 when Array
                   id.publisher.join("/")
                 when String
                   id.publisher
                 else
                   "BS"
                 end

        result = prefix
        result += " #{id.adopted_identifier}" if id.adopted_identifier
        result += " ED#{id.edition}" if id.edition

        result += " (R#{id.reaffirmation_year})" if id.reaffirmation_year

        result = render_translation(result, id)

        result = render_expert_commentary_suffix(result, id)

        result
      end

      def render_adopted_international_standard(id)
        prefix = case id.publisher
                 when Components::Publisher
                   id.publisher.render(context: @context)
                 when Array
                   id.publisher.join("/")
                 when String
                   id.publisher
                 else
                   "BS"
                 end

        result = prefix
        result += " #{id.adopted_identifier}" if id.adopted_identifier
        result += " ED#{id.edition}" if id.edition

        result += " (R#{id.reaffirmation_year})" if id.reaffirmation_year

        if id.translation_lang
          result += " (#{id.translation_lang})"
        elsif id.translation_upper
          result += " (#{id.translation_upper})"
        end

        result = render_expert_commentary_suffix(result, id)

        result
      end

      def render_aerospace_standard(id)
        parts = []
        parts << "BS"
        parts << id.prefix if id.prefix

        if id.number
          number_str = id.number.render(context: @context)

          if id.part
            part_val = id.part.render(context: @context)
            number_str += "-#{part_val}"
          end
          if id.subpart
            subpart_val = id.subpart.render(context: @context)
            number_str += "-#{subpart_val}"
          end

          parts << number_str
        end

        result = parts.join(" ")

        if id.edition&.match?(/^[a-zA-Z]$/)
          result += id.edition
        end

        if id.date
          year_val = id.date.render(context: @context)
          result += ":#{year_val}"
          result += "-#{format('%02d', id.month)}" if id.month
        end

        if id.edition && !id.edition.match?(/^[a-zA-Z]$/)
          result += " v#{id.edition}"
        end

        if id.translation_lang
          result += " (#{id.translation_lang})"
        elsif id.translation_upper
          result += " (#{id.translation_upper})"
        end

        result
      end

      def render_amendment(id)
        base = id.base ? id.base.to_s : ""

        if id.amd_suffix_form
          # Trailing " AMD5" / " AMD AA" suffix form
          suffix = if id.amendment_number&.match?(/^[A-Z]+$/)
                     " AMD #{id.amendment_number}"
                   else
                     " AMD#{id.amendment_number}"
                   end
          base.empty? ? suffix.lstrip : "#{base}#{suffix}"
        else
          # Compact "+A5" / "/A5" join form, with an optional ":year"
          compact = "#{id.separator}A#{id.amendment_number}"
          compact += ":#{id.amendment_year}" if id.amendment_year
          "#{base}#{compact}"
        end
      end

      def render_british_industrial_practice(id)
        result = "BIP #{id.number}"
        result += ":#{id.date.render(context: @context)}" if id.date
        result
      end

      def render_bundled_identifier(id)
        return "" if id.identifiers.nil? || id.identifiers.empty?

        if id.bundle_type
          base_id = id.identifiers.first
          parts_list = id.identifiers[1..].map do |idd|
            part_val = idd.class.attributes.key?(:part) ? idd.part : nil
            if part_val
              pv = part_val.render(context: @context)
              pv.to_s
            else
              idd.to_s
            end
          end.join(" and ")

          result = "#{base_id.to_s.sub(/:.*$/, '')}:#{id.bundle_type} #{parts_list}"
          result += ":#{id.common_year.render(context: @context)}" if id.common_year
          return result
        end

        parts = []

        id.identifiers.each_with_index do |idd, i|
          explicit_prefix = idd.explicit_prefix
          explicit_publisher = idd.explicit_publisher

          if i.zero?
            parts << idd.to_s
          elsif explicit_publisher
            parts << idd.to_s
          elsif explicit_prefix
            abbrev_str = ""
            prefix = idd.class.attributes.key?(:prefix) ? idd.prefix : nil
            if prefix && !prefix.to_s.empty?
              abbrev_str = prefix.to_s
            end
            if idd.number
              number_val = idd.number.render(context: @context)
              abbrev_str += " " if !abbrev_str.empty?
              abbrev_str += number_val.to_s
            end
            if idd.part
              part_val = idd.part.render(context: @context)
              abbrev_str += "-#{part_val}"
            end
            parts << abbrev_str
          else
            abbrev_str = ""
            if idd.number
              number_val = idd.number.render(context: @context)
              abbrev_str = number_val.to_s
            end
            if idd.part
              part_val = idd.part.render(context: @context)
              abbrev_str += "-#{part_val}"
            end
            parts << abbrev_str
          end

          if i < id.identifiers.length - 1
            sep = id.separators[i] || " and "
            parts << sep
          end
        end

        result = parts.join

        if id.common_year && !result.match?(/:#{id.common_year.render(context: @context)}$/)
          result += ":#{id.common_year.render(context: @context)}"
        end

        result
      end

      def render_committee_document(id)
        year_str = if id.date
                     id.date.render(context: @context).to_s[-2, 2]
                   else
                     "00"
                   end

        "#{year_str}/#{id.number} DC"
      end

      def render_consolidated_identifier(id, opts)
        base_id = id.identifiers.first

        base_str = base_id.to_s
        result = base_str.sub(/ ExComm \(.*?\)$/, "")
                .sub(/ ExComm$/, "")
                .sub(/ - TC$/, "")
                .sub(/ PDF$/, "")
                .sub(/ \([A-Z][a-z]+\)$/, "")

        id.identifiers[1..].each do |idd|
          if idd.is_a?(Identifiers::Amendment)
            if idd.amd_suffix_form
              result += if idd.amendment_number&.match?(/^[A-Z]+$/)
                          " AMD #{idd.amendment_number}"
                        else
                          " AMD#{idd.amendment_number}"
                        end
            else
              sep = idd.separator || "+"
              result += "#{sep}A#{idd.amendment_number}"
              result += ":#{idd.amendment_year}" if idd.amendment_year
            end
          elsif idd.is_a?(Identifiers::Corrigendum)
            sep = idd.separator || "+"
            result += "#{sep}C"
            result += idd.corrigendum_number.to_s if idd.corrigendum_number
            result += ":#{idd.corrigendum_year}" if idd.corrigendum_year
          else
            result += idd.to_s
          end
        end

        if base_id.is_a?(Pubid::Identifier)
          base_attrs = base_id.class.attributes
          ec = base_attrs.key?(:expert_commentary) ? base_id.expert_commentary : nil
          if ec
            ect = base_attrs.key?(:expert_commentary_topic) ? base_id.expert_commentary_topic : nil
            result += ect ? " ExComm (#{ect})" : " ExComm"
          end

          tc = base_attrs.key?(:tracked_changes) ? base_id.tracked_changes : nil
          result += " - TC" if tc

          tl = base_attrs.key?(:translation_lang) ? base_id.translation_lang : nil
          if tl
            ts_type = base_attrs.key?(:translation_suffix_type) ? base_id.translation_suffix_type : nil
            result += if ts_type == "version"
                        " (#{tl} version)"
                      elsif ts_type == "Translation"
                        " (#{tl} Translation)"
                      else
                        " (#{tl})"
                      end
          else
            tu = base_attrs.key?(:translation_upper) ? base_id.translation_upper : nil
            if tu
              ts_type = base_attrs.key?(:translation_suffix_type) ? base_id.translation_suffix_type : nil
              result += if ts_type == "Translation"
                          " (#{tu} Translation)"
                        else
                          " (#{tu})"
                        end
            end
          end

          ry = base_attrs.key?(:reaffirmation_year) ? base_id.reaffirmation_year : nil
          result += " (R#{ry})" if ry
        end

        result
      end

      def render_corrigendum(id)
        result = id.base ? id.base.to_s : ""
        result += "#{id.separator}C"
        result += id.corrigendum_number.to_s if id.corrigendum_number
        result += ":#{id.corrigendum_year}" if id.corrigendum_year
        result
      end

      def render_detailed_specification(id)
        parts = []
        parts << "BS"

        if id.number
          number_str = id.number.render(context: @context)
          parts << number_str
        end

        if id.spec_code
          code_val = id.spec_code.render(context: @context)
          result = "#{parts.join(' ')} #{code_val}"
        else
          result = parts.join(" ")
        end

        if id.date
          year_val = id.date.render(context: @context)
          result += ":#{year_val}"
        end

        result
      end

      def render_disc(id)
        parts = []
        parts << "DISC"

        if id.number
          number_str = id.number.render(context: @context)
          if id.part
            part_val = id.part.render(context: @context)
            number_str += "-#{part_val.to_s.strip}"
          end
          parts << "PD #{number_str}"
        end

        result = parts.join(" ")

        result += ":#{id.date}" if id.date

        result
      end

      def render_draft_document(id)
        parts = []

        type_abbr = id.type&.abbr || "DD"
        parts << type_abbr

        if id.number
          number_str = id.number.render(context: @context)

          if id.part
            part_val = id.part.render(context: @context)
            number_str += "-#{part_val.to_s.strip}"
          end
          if id.subpart
            subpart_val = id.subpart.render(context: @context)
            number_str += "-#{subpart_val.to_s.strip}"
          end

          parts << number_str
        end

        result = parts.join(" ")

        if id.date
          year_val = id.date.render(context: @context)
          result += ":#{year_val}"
        end

        result += " v#{id.edition}" if id.edition

        result = render_translation(result, id)

        result
      end

      def render_electronic_book(id)
        parts = []
        parts << "EP"

        if id.number
          number_str = id.number.render(context: @context)

          if id.part
            part_val = id.part.render(context: @context)
            number_str += "-#{part_val.to_s.strip}"
          end
          if id.subpart
            subpart_val = id.subpart.render(context: @context)
            number_str += "-#{subpart_val.to_s.strip}"
          end

          parts << number_str
        end

        result = parts.join(" ")

        if id.date
          year_val = id.date.render(context: @context)
          result += ":#{year_val}"
        end

        result += " Version #{id.edition}" if id.edition

        result
      end

      def render_expert_commentary(id)
        base_str = id.base.to_s
        base_str = base_str.sub(/ (Expert Commentary|ExComm(\s*\(.*\))?)$/, "")

        case id.format
        when "full"
          "#{base_str} Expert Commentary"
        when "abbr_with_topic"
          "#{base_str} ExComm (#{id.topic})"
        else
          "#{base_str} ExComm"
        end
      end

      def render_explanatory_supplement(id)
        parts = []
        parts << "BS"

        if id.number
          number_str = id.number.render(context: @context)

          if id.part
            part_val = id.part.render(context: @context)
            number_str += "-#{part_val}"
          end
          if id.subpart
            subpart_val = id.subpart.render(context: @context)
            number_str += "-#{subpart_val}"
          end

          parts << number_str
        end

        result = parts.join(" ")

        if id.date
          year_val = id.date.render(context: @context)
          result += ":Explanatory Supplement:#{year_val}"
          result += "-#{format('%02d', id.month)}" if id.month
        end

        result
      end

      def render_flex(id)
        parts = []
        parts << "BSI Flex"

        if id.number
          number_str = id.number.render(context: @context)
          if id.part
            part_val = id.part.render(context: @context)
            number_str += "-#{part_val}"
          end
          if id.subpart
            subpart_val = id.subpart.render(context: @context)
            number_str += "-#{subpart_val}"
          end
          parts << number_str
        end

        result = parts.join(" ")

        result += " v#{id.edition}" if id.edition

        if id.date
          year_val = id.date.render(context: @context)
          result += ":#{year_val}"
          result += "-#{format('%02d', id.month)}" if id.month
        end

        result
      end

      def render_handbook(id)
        abbr = id.original_abbr || "Handbook"

        number_str = id.number.render(context: @context)
        if id.part
          part_val = id.part.render(context: @context)
          number_str += "-#{part_val.to_s.strip}"
        end

        result = "#{abbr} #{number_str}"
        result += ":#{id.date.render(context: @context)}" if id.date
        result
      end

      def render_index(id)
        parts = []
        parts << id.publisher.to_s if id.publisher

        if id.number
          number_str = id.number.render(context: @context)
          parts << number_str
        end

        result = parts.join(" ")

        if id.issue_number
          result += " Index Issue #{id.issue_number}"
        elsif id.index_format == "colon"
          result += ":Index"
        else
          result += " Index"
        end

        if id.date
          year_val = id.date.render(context: @context)
          result += ":#{year_val}"
        end

        result
      end

      def render_method(id)
        parts = []
        parts << id.publisher.to_s if id.publisher

        if id.number
          number_str = id.number.render(context: @context)
          if id.part
            part_val = id.part.render(context: @context)
            number_str += "-#{part_val}"
          end
          parts << number_str
        end

        result = parts.join(" ")

        if id.method_to
          result += ":Methods #{id.method_code} to #{id.method_to}"
        elsif id.method_and
          result += ":Methods #{id.method_code} and #{id.method_and}"
        else
          method_word = id.is_plural ? "Methods" : "Method"
          result += ":#{method_word} #{id.method_code}"
        end

        if id.date
          year_val = id.date.render(context: @context)
          result += ":#{year_val}"
        end

        result
      end

      def render_national_annex(id)
        result = "NA"

        if id.na_supplements&.any?
          id.na_supplements.each do |supp|
            if supp.is_a?(Identifiers::Amendment)
              result += "+A#{supp.amendment_number}:#{supp.amendment_year}"
            elsif supp.is_a?(Identifiers::Corrigendum)
              result += "+C#{supp.corrigendum_number}:#{supp.corrigendum_year}"
            end
          end
        end

        result += " to "

        result += if id.base_doc
                    id.base_doc.to_s
                  else
                    render_single_identifier(id)
                  end

        result
      end

      def render_practice_guide(id)
        result = "PP #{id.number}"
        result += ":#{id.date.render(context: @context)}" if id.date
        result
      end

      def render_publicly_available_specification(id)
        parts = []
        type_abbr = id.type&.abbr || "PAS"
        parts << type_abbr

        if id.number
          number_str = id.number.render(context: @context)

          if id.second_number
            second_val = id.second_number.render(context: @context)
            number_str += "/#{second_val}"
          end

          if id.part
            part_val = id.part.render(context: @context)
            number_str += "-#{part_val.to_s.strip}"
          end
          if id.subpart
            subpart_val = id.subpart.render(context: @context)
            number_str += "-#{subpart_val.to_s.strip}"
          end

          parts << number_str
        end

        result = parts.join(" ")

        if id.date
          year_val = id.date.render(context: @context)
          result += ":#{year_val}"
          result += "-#{format('%02d', id.month)}" if id.month
        end

        result += " v#{id.edition}" if id.edition

        result = render_translation(result, id)

        result
      end

      def render_published_document(id)
        parts = []
        type_abbr = id.type&.abbr || "PD"
        parts << type_abbr

        if id.number
          number_str = id.number.render(context: @context)

          if id.second_number
            second_val = id.second_number.render(context: @context)
            number_str += "/#{second_val}"
          end

          if id.part
            part_val = id.part.render(context: @context)
            number_str += "-#{part_val.to_s.strip}"
          end
          if id.subpart
            subpart_val = id.subpart.render(context: @context)
            number_str += "-#{subpart_val.to_s.strip}"
          end

          parts << number_str
        end

        result = parts.join(" ")

        if id.date
          year_val = id.date.render(context: @context)
          result += ":#{year_val}"
          result += "-#{format('%02d', id.month)}" if id.month
        end

        result += " v#{id.edition}" if id.edition

        result = render_translation(result, id)

        result
      end

      def render_section(id)
        parts = []
        parts << id.publisher.to_s if id.publisher

        if id.number
          number_str = id.number.render(context: @context)
          parts << number_str
        end

        result = parts.join(" ")

        if id.section_format == "colon"
          result += ":Section #{id.section_id}"
        else
          result += " Section #{id.section_id}"
        end

        if id.date
          year_val = id.date.render(context: @context)
          result += ":#{year_val}"
        end

        result
      end

      def render_set(id)
        return "" if id.identifiers.nil? || id.identifiers.empty?

        parts = []
        id.identifiers.each_with_index do |idd, i|
          parts << idd.to_s
          if i < id.identifiers.length - 1
            parts << " + "
          end
        end

        parts.join
      end

      def render_standalone_amendment(id)
        base = if id.corrigendum
                 "AMD Corrigendum #{id.number}"
               else
                 "AMD #{id.number}"
               end

        id.parenthesized ? "(#{base})" : base
      end

      def render_supplement_document(id)
        base_str = id.base.to_s

        if id.reverse_format
          supplement_str = if id.supplement_type == "No."
                             "Supplement No. #{id.supplement_number} (#{id.supplement_year})"
                           else
                             "Supplement #{id.supplement_number} (#{id.supplement_year})"
                           end
          "#{supplement_str} to #{base_str}"
        else
          supplement_str = if id.supplement_type == "No."
                             "#{id.separator}Supplement No. #{id.supplement_number}:#{id.supplement_year}"
                           else
                             "#{id.separator}Supplement #{id.supplement_number}:#{id.supplement_year}"
                           end
          "#{base_str}#{supplement_str}"
        end
      end

      def render_supplementary_index(id)
        parts = []
        parts << "BS"

        if id.number
          number_str = id.number.render(context: @context)

          if id.part
            part_val = id.part.render(context: @context)
            number_str += "-#{part_val}"
          end
          if id.subpart
            subpart_val = id.subpart.render(context: @context)
            number_str += "-#{subpart_val}"
          end

          parts << number_str
        end

        result = parts.join(" ")

        if id.date
          year_val = id.date.render(context: @context)
          result += " Supplementary Index:#{year_val}"
          result += "-#{format('%02d', id.month)}" if id.month
        end

        result
      end

      def render_technical_specification(id)
        parts = []
        parts << "TS"

        if id.number
          number_str = id.number.render(context: @context)

          if id.part
            part_val = id.part.render(context: @context)
            number_str += "-#{part_val}"
          end
          if id.subpart
            subpart_val = id.subpart.render(context: @context)
            number_str += "-#{subpart_val}"
          end

          parts << number_str
        end

        result = parts.join(" ")

        if id.date
          year_val = id.date.render(context: @context)
          result += ":#{year_val}"
          result += "-#{format('%02d', id.month)}" if id.month
        end

        result
      end

      def render_test_method(id)
        parts = []
        parts << "BS"

        if id.number
          number_str = id.number.render(context: @context)
          parts << number_str
        end

        result = parts.join(" ")

        if id.test_series && id.test_id
          result += ":#{id.test_series}:#{id.test_id}"
        end

        if id.date
          year_val = id.date.render(context: @context)
          result += ":#{year_val}"
        end

        result
      end

      def render_value_added_publication(id, opts)
        base_str = id.base.to_s(**opts)

        case id.format
        when "TC"
          "#{base_str} - TC"
        when "PDF"
          "#{base_str} PDF"
        when "BOOK"
          "#{base_str} BOOK"
        else
          base_str
        end
      end

      # ------------------------------------------------------------------
      # Shared helpers
      # ------------------------------------------------------------------

      def render_translation(result, id)
        if id.translation_lang
          suffix_type = id.translation_suffix_type if id.class.attributes.key?(:translation_suffix_type)
          result += if suffix_type == "version"
                      " (#{id.translation_lang} version)"
                    elsif suffix_type == "Translation"
                      " (#{id.translation_lang} Translation)"
                    else
                      " (#{id.translation_lang})"
                    end
        elsif id.translation_upper
          suffix_type = id.translation_suffix_type if id.class.attributes.key?(:translation_suffix_type)
          result += if suffix_type == "Translation"
                      " (#{id.translation_upper} Translation)"
                    else
                      " (#{id.translation_upper})"
                    end
        end
        result
      end

      def render_expert_commentary_suffix(result, id)
        if id.expert_commentary
          if id.expert_commentary_topic
            result += " ExComm (#{id.expert_commentary_topic})"
          else
            result += " ExComm"
          end
        end
        result
      end
    end
  end
end
