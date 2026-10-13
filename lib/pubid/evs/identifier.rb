# frozen_string_literal: true

module Pubid
  module Evs
    # An EVS identifier: the national prefix ("EVS" / "prEVS") over a CEN
    # adoption, an ISO/IEC adoption, or a plain Estonian standard, plus the
    # EVS-list supplements and the language code.
    #
    #   "EVS-EN 18216:2026"            (base: EN 18216:2026)
    #   "EVS-EN ISO 9001:2015/A1:2024" (base: EN ISO 9001:2015/A1:2024)
    #   "EVS-ISO 9001:2015"            (intl_org: ISO)
    #   "EVS-IEC 62368-1:2020"         (intl_org: IEC)
    #   "EVS 921:2019", "EVS-TS 1:2019"
    #
    # Shared supplements (pubid#517-list): the national annex ("+NA:2010" /
    # "/NA"), the AMD and COR spellings, and the trailing language code
    # (" et" / " en" / " et-en"). The supplement separators are semantic
    # ("+X" a full standard plus the supplement, "/X" the supplement only)
    # and are preserved as captured.
    class Identifier < ::Pubid::Identifier
      attribute :base, ::Pubid::Identifier, polymorphic: true
      # "-" or " " — preserves the printed separator ("EVS-EN" vs "EVS EN")
      attribute :separator, :string, default: -> { "-" }
      attribute :draft_prefix, :boolean, default: -> { false }
      attribute :language, :string

      # National annex: separator ("+"/"/") and optional year
      attribute :na_separator, :string
      attribute :na_year, :string
      # AMD amendment spelling
      attribute :amd_separator, :string
      attribute :amd_kind, :string
      attribute :amd_number, :string
      attribute :amd_year, :string
      # COR corrigendum spelling
      attribute :cor_separator, :string
      attribute :cor_kind, :string
      attribute :cor_number, :string
      attribute :cor_year, :string

      def to_s(**opts)
        render(format: :human, **opts)
      end

      def self.parse(string)
        unless string.is_a?(String)
          raise Pubid::Errors::InvalidInputError,
                Pubid::INPUT_NOT_A_STRING_MESSAGE
        end

        if string.length > Pubid::MAX_INPUT_LENGTH
          raise Pubid::Errors::InvalidInputError, Pubid::INPUT_TOO_LONG_MESSAGE
        end

        Pubid::Evs.parse(string)
      end
    end
  end
end
