# frozen_string_literal: true

module Pubid
  module Ieee
    # Human-readable renderer for IEEE identifiers.
    #
    # Produces strings like:
    #   "IEEE Std 802.11-2020"
    #   "IEEE Std 535-2013/Cor. 1-2017"
    #   "ANSI C37.61-1973 and IEEE Std 321-1973"
    #
    # The renderer is registered as the +:human+ format in the IEEE format
    # registry and invoked via +render(format: :human)+.
    #
    # For wrapper types (DualPublished, AdoptedStandard, etc.) the renderer
    # composes child identifiers. For simple identifiers it delegates to the
    # identifier's own publisher/code/relationship helpers.
    class Renderer < ::Pubid::Renderers::Base
      def render(context: nil, **opts)
        id = @id

        result = render_id(id)
        return result unless opts[:trademark]

        "#{result}#{Pubid::Ieee.trademark_symbol(result)}"
      end

      private

      # Dispatch to the type-specific renderer, returning the composed string
      # (the trademark symbol, if requested, is appended by #render).
      def render_id(id)
        case id
        when Identifiers::DualPublished
          render_dual_published(id)
        when Identifiers::DualIdentifier
          render_dual_identifier(id)
        when Identifiers::AdoptedStandard
          render_adopted_standard(id)
        when Identifiers::RedlinedStandard
          render_redlined_standard(id)
        when Identifiers::Corrigendum
          render_corrigendum(id)
        when Identifiers::InterpretationIdentifier
          render_interpretation(id)
        when Identifiers::ConformanceIdentifier
          render_conformance(id)
        when Identifiers::MultiNumberedIdentifier
          render_multi_numbered(id)
        when Identifiers::ParentheticalIdentifier
          render_parenthetical(id)
        when Identifiers::CsaDualPublished
          render_csa_dual_published(id)
        when Identifiers::IecIeeeCopublished
          render_iec_ieee_copublished(id)
        when Identifiers::SiStandard
          render_si_standard(id)
        when Identifiers::JointDevelopment
          id.to_s
        else
          render_base(id)
        end
      end

      # ------------------------------------------------------------------
      # Base IEEE identifier rendering
      # ------------------------------------------------------------------

      def render_base(id)
        parts = []

        # Publisher(s) - handle copublisher array properly
        if id.copublisher && !id.copublisher.empty?
          parts << [id.publisher, *id.copublisher].join("/")
        else
          parts << id.publisher
        end

        # Draft status
        parts << id.draft_status if id.draft_status

        # Type - only render for IEEE/AIEE publishers, and only for non-projects.
        # An unapproved draft is not yet a standard, so per IEEE guidance the
        # "Std" token is dropped from the type when draft_status is "Unapproved"
        # (e.g. "Draft Std" -> "Draft", "Std" -> "").
        should_render_type = id.publisher&.match?(/^(IEEE|AIEE)/)

        if should_render_type && !id.typed_stage&.project_status && id.type && !id.type.to_s.strip.empty? && id.type != "P"
          type_str = id.type.dup
          type_str = type_str.sub(/^P/, "") if type_str.start_with?("P")
          if id.draft_status.to_s.match?(/unapproved/i)
            type_str = type_str.gsub(/\bStd\b/i, "").squeeze(" ").strip
          end
          parts << type_str unless type_str.strip.empty?
        end

        # Code - with P prefix for projects (concatenated, not separated)
        if id.code_obj
          result = id.code_obj.to_s

          # Prepend P if this is a project AND code doesn't already have P
          if id.typed_stage&.project_status && should_render_type && !result.start_with?("P")
            result = "P#{result}"
          end

          # Only attach year to code if there's no edition, no month, and no draft
          result += "-#{id.year}" if id.year && !id.draft_obj && !id.edition && !id.month

          # Append the numbered/lettered revision inline, in IEEE's native
          # position — right after the code number and before the draft
          # ("P802.16Rev2/D3"). Keeps a revision distinct from its base standard.
          result += "Rev#{id.revision}" if id.revision

          # Append draft to code - with or without space based on original format
          if id.draft_obj
            result += id.space_before_draft ? " #{id.draft_obj}" : id.draft_obj.to_s
          end

          # Append interpretation notation (/INT)
          result += "/INT" if id.interpretation

          # Conformance is always built as a ConformanceIdentifier wrapper
          # (render_conformance), never inline on a base standard — the base no
          # longer carries a conf_number attribute.

          # Append ASHRAE joint publication (/ASHRAE Guideline NN-YYYY)
          if id.ashrae_number
            result += "/ASHRAE Guideline #{id.ashrae_number}"
            result += "-#{id.ashrae_year}" if id.ashrae_year
          end

          # Append IEEE cross-reference (/C62.22.1-1996)
          result += id.crossref if id.crossref

          parts << result
        elsif should_render_type && id.typed_stage&.project_status
          # No code but is a project - add standalone P
          parts << "P"
        end

        # Edition - with year if present (IEC style)
        if id.edition
          edition_str = "Edition #{id.edition}"
          if id.year
            edition_str += " #{id.year}"
            edition_str += "-#{id.edition_month}" if id.edition_month
          end
          parts << edition_str
        end

        # Build the main identifier (without month yet)
        result = parts.join(" ")

        # Month/Day - append directly to avoid extra space before comma
        if id.month
          result += ", #{id.month}"
          result += " #{id.day}" if id.day
          if id.year && !id.edition
            result += " #{id.year}"
          end
        end

        # Add parenthetical content if present
        parentheticals = []

        reaff = id.reaffirmed
        if reaff && !reaff.to_s.strip.empty?
          parentheticals << "(R#{reaff})"
        end

        if id.parenthetical_content
          parentheticals << "(#{id.parenthetical_content})"
        elsif id.relationships && !id.relationships.empty?
          relationship_str = id.relationships.join(" / ")
          parentheticals << "(#{relationship_str})"
        elsif id.revision_of
          parentheticals << "(Revision of IEEE Std #{id.revision_of})"
        elsif id.amendment_to
          parentheticals << "(Amendment to IEEE Std #{id.amendment_to})"
        elsif id.adoption
          parentheticals << "(Adoption of #{id.adoption})"
        elsif id.note && !id.note.to_s.strip.empty?
          parentheticals << "(#{id.note})"
        end

        result += " #{parentheticals.join(' ')}" unless parentheticals.empty?

        # Book nickname - outside parentheses in square brackets
        result += " [#{id.nickname}]" if id.nickname && !id.nickname.to_s.strip.empty?

        # Redline suffix
        result += " - Redline" if id.redline

        result
      end

      # ------------------------------------------------------------------
      # Wrapper types
      # ------------------------------------------------------------------

      def render_dual_published(id)
        "#{id.first_identifier} and #{id.second_identifier}"
      end

      def render_dual_identifier(id)
        "#{id.first_identifier} and #{id.second_identifier}"
      end

      def render_adopted_standard(id)
        result = id.ieee_identifier.to_s
        if id.adopted_identifiers && !id.adopted_identifiers.empty?
          adopted_strs = id.adopted_identifiers.map(&:to_s)
          result += " (#{adopted_strs.join(' and ')})"
        end
        result
      end

      def render_redlined_standard(id)
        result = id.base.to_s
        result += " (Revision of #{id.revision_of})" if id.revision_of
        result += " - Redline" if id.redline
        result
      end

      def render_corrigendum(id)
        return render_base(id) unless id.base

        result = id.base.to_s
        result += "/Cor"
        result += ". " if id.number # Add period and space for formal format
        result += id.number if id.number
        result += "-#{id.year}" if id.year
        result
      end

      def render_interpretation(id)
        return render_base(id) unless id.base

        result = id.base.to_s
        result += "/INT"
        result += "-#{id.year}" if id.year
        result
      end

      def render_conformance(id)
        return render_base(id) unless id.base

        result = id.base.to_s
        result += "/Conformance#{id.number}" if id.number
        result += "-#{id.year}" if id.year
        result
      end

      def render_multi_numbered(id)
        return id.primary_identifier.to_s unless id.secondary_identifier

        secondary_code = id.secondary_identifier.code.to_s
        if secondary_code.start_with?("C") && secondary_code.match?(/^C\d+\./)
          "#{id.primary_identifier}/#{id.secondary_identifier}"
        else
          "#{id.primary_identifier} and #{id.secondary_identifier}"
        end
      end

      def render_parenthetical(id)
        result = id.base.to_s
        result += " (#{id.parenthetical_identifier})" if id.parenthetical_identifier
        result
      end

      def render_csa_dual_published(id)
        csa_str = id.csa_identifier.to_s
        csa_str = "CSA #{csa_str}" unless csa_str.start_with?("CSA", "CAN/")

        "#{id.ieee_identifier}/#{csa_str}"
      end

      def render_iec_ieee_copublished(id)
        result = "IEC/IEEE"
        result += " #{id.copublished_number}" if id.copublished_number
        result += id.draft_info if id.draft_info
        result += " IEC:#{id.iec_year}" if id.iec_year
        result += " #{id.date_info}" if id.date_info
        result
      end

      def render_si_standard(id)
        parts = []

        # Publisher (IEEE/ASTM)
        parts << "IEEE/ASTM"

        # Type (SI or PSI based on typed_stage)
        parts << if id.typed_stage&.abbr&.include?("PSI")
                   "PSI"
                 else
                   "SI"
                 end

        # Code (number) with draft version for PSI
        code_part = id.code.to_s
        if id.draft_obj
          code_part += "/D#{id.draft_obj.version}"
        end
        parts << code_part if id.code

        # Date
        if id.month && id.year
          parts << ", #{id.month} #{id.year}"
        elsif id.year
          parts << "-#{id.year}"
        end

        # Relationships (if present)
        # Join parts with spaces, but don't insert a space before parts
        # that start with "-" or "," (e.g., "-2010", ", July 2014") so the
        # SI form renders as "SI 10-2010" not "SI 10 -2010".
        result = parts.each_with_object([]) do |part, acc|
          if acc.empty? || part.to_s.start_with?("-", ",")
            acc << part.to_s
          else
            acc << " " << part.to_s
          end
        end.join
        if id.relationships && !id.relationships.empty?
          rel_strs = id.relationships.map(&:to_s)
          result += " (#{rel_strs.join(' / ')})"
        end

        result
      end
    end
  end
end
