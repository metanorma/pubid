# frozen_string_literal: true

module Pubid
  module Asme
    # Human-readable renderer for ASME identifiers.
    #
    # Produces strings like:
    #   "ASME B16.5-2020"
    #   "CSA B44.10/ASME A17.10"
    #   "ASME BPVC III.1.NB-2023"
    #   "ASME PTC 4-2013"
    #
    # The renderer is registered as the `:human` format in the ASME format
    # registry and invoked via `render(format: :human)`.
    class Renderer < ::Pubid::Renderers::Base
      def render(context: nil, **opts)
        id = @id
        parts = []

        if id.first_publisher && id.first_code
          # CSA B44.10/ASME A17.10 or API 579-2/ASME PTB-14 format
          parts << id.first_publisher
          parts << id.first_code
          parts << "/#{id.second_publisher}" if id.second_publisher
          parts << id.number.to_s if id.number && id.number.to_s != ""
        elsif id.joint_publisher
          # ISO/ASME or ASME/ANS format
          parts << id.joint_publisher
          parts << id.number.to_s if id.number && id.number.to_s != ""
        else
          # Standard ASME format
          parts << id.publisher if id.publisher
          parts << id.number.to_s if id.number
        end

        result = parts.join(" ")

        if id.ptc_suffix
          result += " #{id.ptc_suffix}"
        end

        if id.csa_number
          result += "/CSA #{id.csa_number}"
        end

        if id.handbook
          result += " Handbook"
        end

        if id.draft_year
          result += "-#{id.draft_year}"
        elsif id.year
          result += "-#{id.year}"
        end

        result += " #{id.parenthetical_revision}" if id.parenthetical_revision
        result += " (#{id.language})" if id.language
        result += " (#{id.reaffirmation})" if id.reaffirmation
        result += " #{id.revision_note}" if id.revision_note

        # Normalize all em-dashes and en-dashes to regular dash
        result.gsub(/[–—]/, "-")
      end
    end
  end
end
