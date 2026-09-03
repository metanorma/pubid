# frozen_string_literal: true

module Pubid
  module Amca
    # Human-readable renderer for AMCA identifiers.
    #
    # Produces strings like:
    #   "AMCA Standard 210-16"
    #   "AMCA Publication 211-22 (Rev. 01-23)"
    #   "ANSI/AMCA 204 Interp"
    #   "AMCA 99 JW Interp"
    #
    # The renderer is registered as the `:human` format in the AMCA format
    # registry and invoked via `render(format: :human)`.
    class Renderer < ::Pubid::Renderers::Base
      def render(context: nil, **opts)
        id = @id

        case id
        when Identifiers::Publication
          render_publication(id)
        when Identifiers::Interpretation
          render_interpretation(id)
        else
          render_base(id)
        end
      end

      private

      def render_base(id)
        parts = []
        parts << id.copublisher if id.copublisher
        t = id.class.respond_to?(:type) ? id.class.type : nil
        if t.is_a?(Hash) && t[:title]
          parts << t[:title].to_s
        end
        parts << id.number.to_s
        parts << "-#{id.year}" if id.year

        result = parts.compact.join(" ")

        if id.copublisher&.include?("/") && id.year
          type_title = t.is_a?(Hash) ? t[:title].to_s : ""
          result = "#{id.copublisher} #{type_title} #{id.number}-#{id.year}"
        end

        result += " (#{id.reaffirmed})" if id.reaffirmed

        result
      end

      def render_publication(id)
        parts = []
        parts << id.copublisher if id.copublisher
        parts << "Publication"
        parts << id.number.to_s
        parts << "-#{id.year}" if id.year
        parts << " (Rev. #{id.revision})" if id.revision
        parts << " (#{id.reaffirmed})" if id.reaffirmed && !id.revision

        parts.join(" ").squeeze(" ")
      end

      def render_interpretation(id)
        parts = []
        parts << id.copublisher if id.copublisher
        parts << id.number.to_s

        if id.interpretation_code
          parts << "– #{id.interpretation_code}"
        elsif id.year
          parts << "-#{id.year}"
        end

        parts << " #{id.suffix}" if id.suffix

        parts.join(" ").squeeze(" ")
      end
    end
  end
end
