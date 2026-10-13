# frozen_string_literal: true

module Pubid
  module Evs
    # Human-readable renderer for EVS identifiers.
    #
    #   "EVS-EN 18216:2026"
    #   "EVS-EN ISO 9001:2015/A1:2024"
    #   "EVS-ISO 9001:2015"
    #   "EVS-IEC 62368-1:2020"
    #   "EVS 921:2019"
    #   "EVS-TS 1:2019"
    #   "prEVS-EN 100:2026"
    #   "EVS-EN 1993-1-1:2005+NA:2010 et"
    class Renderer < ::Pubid::Renderers::Base
      def render(context: nil, **_opts)
        result = +""
        result << "pr" if @id.draft_prefix
        result << "EVS#{@id.separator}"
        result << body
        result << supplement(@id.amd_separator, @id.amd_kind, @id.amd_number, @id.amd_year)
        result << supplement(@id.cor_separator, @id.cor_kind || "COR", @id.cor_number, @id.cor_year)
        result << supplement(@id.na_separator, "NA", nil, @id.na_year)
        result << " #{@id.language}" if @id.language
        result
      end

      private

      # The adopted CEN identifier renders with its own "EN …" prefix; the
      # ISO/IEC and plain shapes compose from their captures.
      def body
        case @id
        when Pubid::Evs::Identifiers::NationalAdoption
          @id.base.to_s
        when Pubid::Evs::Identifiers::InternationalAdoption
          org = "#{@id.intl_org} #{@id.number}"
          org << "-#{@id.part}" if @id.part
          org << ":#{@id.year}" if @id.year
          org
        else
          plain = +""
          plain << "#{@id.evs_type} " if @id.evs_type
          plain << @id.number.to_s
          plain << ":#{@id.year}" if @id.year
          plain
        end
      end

      # The separator is semantic ("+X" a full standard plus the
      # supplement, "/X" the supplement only, " AMD" the space spelling)
      # and prints as captured.
      def supplement(separator, kind, number, year)
        return "" unless separator

        face = +"#{separator}#{kind}"
        face << number.to_s if number
        face << ":#{year}" if year
        face
      end
    end
  end
end
