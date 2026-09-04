# frozen_string_literal: true

module Pubid
  module Jcgm
    # Human-readable renderer for JCGM identifiers.
    #
    # Produces strings like:
    #   "JCGM 100:2008"
    #   "JCGM 100:2008/Amd 1:2023"
    #   "JCGM GUM-6:2020"
    #
    # The renderer is registered as the `:human` format in the JCGM format
    # registry and invoked via `render(format: :human)`.
    class Renderer < ::Pubid::Renderers::Base
      def render(context: nil, **opts)
        case @id
        when Identifiers::Amendment then render_amendment(@id, context)
        when Identifiers::Corrigendum then render_corrigendum(@id)
        when Identifiers::GumGuide then render_gum_guide(@id, context)
        when Identifiers::Meeting then render_meeting(@id)
        else render_single(@id)
        end
      end

      private

      def render_corrigendum(id)
        # Two surface forms:
        #   "JCGM 200:2008 Corrigendum"  — number absent (word form)
        #   "JCGM 101:2008/Cor 1:2009"   — number present (numbered form)
        return "#{id.base}/Cor #{id.number}#{corrigendum_date_suffix(id)}" if id.number

        "#{id.base} Corrigendum"
      end

      def corrigendum_date_suffix(id)
        id.date ? ":#{id.date}" : ""
      end

      # Two surface forms:
      #   "JCGM 17th Meeting (2012)"  — date present (published records)
      #   "JCGM 17th Meeting"         — date absent (partial reference)
      # The ordinal alone names the meeting, so the dateless form is a valid
      # identifier and must stay re-parseable (the parser makes the " (YYYY)"
      # group optional to match).
      def render_meeting(id)
        base = "JCGM #{id.ordinal} Meeting"
        id.date ? "#{base} (#{id.date.year})" : base
      end

      def render_single(id)
        parts = [id.publisher_portion]
        parts << id.number_portion unless id.number_portion.empty?
        result = parts.join(" ")
        result += id.language_portion if id.languages&.any?
        result
      end

      def render_amendment(id, context)
        result = id.base.to_s if id.base
        result += "/Amd"
        result += " #{id.number}" if id.number
        result += ":#{id.date}" if id.date
        result
      end

      def render_gum_guide(id, context)
        parts = []
        parts << id.publisher.publisher if id.publisher
        parts << "GUM-#{id.number}" if id.number

        result = parts.join(" ")
        result += ":#{id.date}" if id.date
        result += gum_language_portion(id) if id.languages&.any?
        result
      end

      def gum_language_portion(id)
        return "" unless id.languages&.any?

        codes = id.languages.map do |lang|
          lang.original_code || lang.code
        end

        "(#{codes.join('/')})"
      end
    end
  end
end
