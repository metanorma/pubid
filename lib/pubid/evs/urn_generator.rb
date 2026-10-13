# frozen_string_literal: true

module Pubid
  module Evs
    # URNs mirror the CEN adoption namespace with the national-body prefix:
    #
    #   "EVS-EN 18216:2026"            → urn:evs:en:18216:2026
    #   "EVS-EN ISO 14001:2026"        → urn:evs:en:iso:14001:2026
    #   "EVS-EN ISO/IEC 27017:2026"    → urn:evs:en:iso-iec:27017:2026
    #   "EVS-EN ISO 9001:2015/A1:2024" → urn:evs:en:iso:9001:2015:amd:1:2024
    #   "EVS-ISO 9001:2015"            → urn:evs:iso:9001:2015
    #   "EVS-IEC 62368-1:2020"         → urn:evs:iec:62368-1:2020
    #   "EVS 921:2019"                 → urn:evs:921:2019
    #   "EVS-TS 1:2019"                → urn:evs:ts:1:2019
    #
    # Generation delegates to the adopted CEN identifier's URN and swaps the
    # `urn:cen:` namespace for `urn:evs:`, so the two stay consistent by
    # construction; the ISO/IEC and plain shapes compose from their captures.
    class UrnGenerator < Pubid::UrnGenerator::Base
      CEN_NAMESPACE = "urn:cen:"
      EVS_NAMESPACE = "urn:evs:"

      def generate
        segments = +""
        segments << "pr:" if identifier.draft_prefix

        segments << if identifier.is_a?(Identifiers::NationalAdoption)
                      adopted_urn = identifier.base.to_urn
                      unless adopted_urn.start_with?(CEN_NAMESPACE)
                        raise Errors::ParseError,
                              "expected adopted CEN URN, got #{adopted_urn.inspect}"
                      end
                      adopted_urn.delete_prefix(CEN_NAMESPACE)
                    else
                      body = +""
                      if identifier.is_a?(Identifiers::InternationalAdoption)
                        body << "#{identifier.intl_org.downcase}:"
                        body << identifier.number.to_s
                        body << "-#{identifier.part}" if identifier.part
                      else
                        body << "#{identifier.evs_type.downcase}:" if identifier.evs_type
                        body << identifier.number.to_s
                      end
                      body << ":#{identifier.year}" if identifier.year
                      body
                    end

        segments << ":na" << ":#{identifier.na_year}" if identifier.na_separator && identifier.na_year
        segments << ":na" if identifier.na_separator && !identifier.na_year
        if identifier.amd_separator
          # the consolidation marker mirrors the cen vocabulary: "+A1" is
          # "plus:amd:1", the slash and space spellings carry no marker
          segments << ":plus" if identifier.amd_separator == "+"
          segments << ":amd"
          segments << ":#{identifier.amd_number}" if identifier.amd_number
          segments << ":#{identifier.amd_year}" if identifier.amd_year
        end
        if identifier.cor_separator
          segments << ":plus" if identifier.cor_separator == "+"
          segments << ":cor"
          segments << ":#{identifier.cor_number}" if identifier.cor_number
          segments << ":#{identifier.cor_year}" if identifier.cor_year
        end
        segments << ":#{identifier.language}" if identifier.language

        "#{EVS_NAMESPACE}#{segments}"
      end
    end
  end
end
