# frozen_string_literal: true

module Pubid
  module Bipm
    # Human-readable renderer for the four BIPM identifier families. Registered
    # as the `:human` format and invoked via `render(format: :human)`.
    class Renderer < ::Pubid::Renderers::Base
      def render(context: nil, **_opts)
        case @id
        when Identifiers::CommitteeDocument then render_committee(@id)
        when Identifiers::Meeting then render_meeting(@id)
        when Identifiers::MetrologiaArticle then render_metrologia(@id)
        when Identifiers::SiBrochure then render_si_brochure(@id)
        else
          raise "Cannot render BIPM identifier: #{@id.class}"
        end
      end

      private

      # Optional " <number>" segment (with a leading space), or "" when absent.
      def number_segment(id)
        id.number ? " #{id.number}" : ""
      end

      # Optional " (<year>[, <lang>])" segment (with a leading space), or ""
      # when the year is absent (a partial reference). `lang` is the trailing
      # ", E"/", F" suffix carried only by the short committee form.
      def year_segment(id, lang: "")
        id.year ? " (#{id.year}#{lang})" : ""
      end

      def render_committee(id)
        return render_committee_long(id) if id.long?

        # short abbreviated key form. The type word is optional — the bare MRA
        # form (e.g. "CIPM 2005-06") has no type_code, so omit it (and its
        # leading space) rather than emit a double space.
        lang = id.language ? ", #{id.language}" : ""
        type = id.type_code ? " #{id.type_code}" : ""
        "#{id.group}#{type}#{number_segment(id)}" \
          "#{year_segment(id, lang: lang)}"
      end

      def render_committee_long(id)
        if id.language == "F"
          name = Identifier::TYPE_NAME_FR[id.type_code]
          conn = Identifier.french_connective(id.group)
          "#{name}#{number_segment(id)} #{conn} #{id.group}#{year_segment(id)}"
        else
          name = Identifier::TYPE_NAME_EN[id.type_code]
          "#{id.group} #{name}#{number_segment(id)}#{year_segment(id)}"
        end
      end

      def render_meeting(id)
        if id.language == "F"
          "#{id.group} #{id.number}<sup>e</sup> réunion#{year_segment(id)}"
        else
          "#{id.group} #{id.ordinal_en} Meeting#{year_segment(id)}"
        end
      end

      def render_metrologia(id)
        result = +"Metrologia"
        result << " #{id.volume}" if id.volume
        result << " #{id.issue}" if id.issue
        result << " #{id.article}" if id.article
        result
      end

      def render_si_brochure(id)
        phrase = id.language == "F" ? "sur le SI " : ""
        lang = id.language ? ", #{id.language}" : ""
        "BIPM SI Brochure #{phrase}#{id.edition} #{id.version} " \
          "(#{id.years}#{lang})"
      end
    end
  end
end
