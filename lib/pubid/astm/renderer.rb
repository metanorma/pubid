# frozen_string_literal: true

module Pubid
  module Astm
    # Human-readable renderer for ASTM identifiers.
    #
    # Consolidates the per-type rendering logic that used to live inline on
    # each identifier class. Produces strings like:
    #   "ASTM E2938-15"
    #   "ASTM RR:A01-1234"
    #   "ASTM MNL45-EB"
    #   "ASTM ADJD2148"
    class Renderer < ::Pubid::Renderers::Base
      def render(context: nil, **opts)
        id = @id

        case id
        when Identifiers::Standard
          render_standard(id)
        when Identifiers::IsoDualPublished
          render_standard(id)
        when Identifiers::ResearchReport
          render_research_report(id)
        when Identifiers::DataSeries
          render_data_series(id)
        when Identifiers::TechnicalReport
          render_technical_report(id)
        when Identifiers::Monograph
          render_monograph(id)
        when Identifiers::Adjunct
          render_adjunct(id)
        when Identifiers::WorkInProgress
          render_work_in_progress(id)
        when Identifiers::Manual
          render_manual(id)
        else
          render_single(id)
        end
      end

      private

      def render_single(id)
        parts = []
        parts << id.publisher if id.publisher
        parts << id.prefix if id.class.attributes.key?(:prefix) && id.prefix
        parts << id.code.to_s if id.code
        parts << "-#{id.year}" if id.year
        parts << id.format_suffix if id.format_suffix
        parts.join(" ")
      end

      def render_standard(id)
        parts = []
        parts << id.publisher if id.publisher

        if id.code
          code_str = id.code.to_s
          if id.code.dual_m
            base_code = "#{id.code.letter}#{id.code.number}"
            code_str = "#{base_code}/#{base_code}M"
          end
          parts << code_str
        end

        result = parts.join(" ")

        if id.year
          result += "-#{year_portion(id)}"
          result += id.sub_year if id.sub_year
        end

        result += "(#{id.reapproval})" if id.reapproval
        result += "e#{id.edition}" if id.edition

        result
      end

      def year_portion(id)
        year_str = id.year.to_s
        year_str.length == 4 ? year_str[-2..] : year_str
      end

      def render_research_report(id)
        parts = []
        parts << id.publisher if id.publisher
        parts << "RR:#{id.committee}-#{id.code.number}" if id.committee && id.code
        parts.join(" ")
      end

      def render_data_series(id)
        parts = []
        parts << id.publisher if id.publisher

        result = parts.join(" ")
        result += " " if id.publisher && !result.end_with?(" ")

        result += "DS"
        result += id.code.to_s if id.code
        result += "HOL" if id.hol_suffix
        result += id.format_suffix if id.format_suffix
        result
      end

      def render_technical_report(id)
        if id.publisher == "ISO/ASTM" && (id.code.nil? || id.code.letter.nil?)
          result = "ISO/ASTMTR"
        else
          result = "TR"
          result += id.code.letter if id.code&.letter
        end
        result += id.code.number if id.code&.number
        result += id.format_suffix if id.format_suffix
        result
      end

      def render_monograph(id)
        parts = []
        parts << id.publisher if id.publisher

        result = parts.join(" ")
        result += " " if id.publisher && !result.end_with?(" ")

        result += "MONO"
        result += id.code.number if id.code
        result += "-#{id.edition}" if id.edition
        result += id.format_suffix if id.format_suffix
        result
      end

      def render_adjunct(id)
        result = []
        result << id.publisher if id.publisher && !id.ea_suffix && !id.dvd_suffix
        result << "ADJ#{id.number}#{'-EA' if id.ea_suffix}#{'DVD' if id.dvd_suffix}"
        result.compact.join(" ")
      end

      def render_work_in_progress(id)
        parts = []
        parts << id.publisher if id.publisher

        result = parts.join(" ")
        result += " " if id.publisher && !result.end_with?(" ")

        result += "WK"
        result += id.code.number if id.code
        result
      end

      def render_manual(id)
        parts = []
        parts << id.publisher if id.publisher
        parts << "MNL"
        parts << "TP" if id.tp_designation
        parts << id.code.number if id.code

        result = parts.join

        result += "-#{id.edition}" if id.edition

        if id.publisher
          result = "#{id.publisher} #{result[id.publisher.length..]}"
        end

        result += "-SUP" if id.supplement
        result += id.format_suffix if id.format_suffix

        result
      end
    end
  end
end
