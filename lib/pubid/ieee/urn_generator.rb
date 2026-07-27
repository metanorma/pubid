# frozen_string_literal: true

module Pubid
  module Ieee
    class UrnGenerator < Pubid::UrnGenerator::Base
      def generate
        parts = ["urn", "ieee"]

        parts << publisher_component

        special_type = special_identifier_type_component
        parts << special_type if special_type

        tc = type_component
        parts << tc if tc

        cc = code_component
        parts << cc if cc

        parts << identifier.year if identifier.year

        dc = draft_component
        parts << dc if dc

        ec = edition_component
        parts << ec if ec

        md = month_day_component
        parts << md if md

        ds = draft_status_component
        parts << ds if ds

        if !special_type && identifier.redline
          parts << "redline"
        end

        if !special_type && identifier.interpretation
          parts << "int"
        end

        # Conformance is always a ConformanceIdentifier wrapper (special_type
        # "conformance"), never inline on a base standard — the base no longer
        # carries a conf_number attribute, so there is no inline conf part.

        if identifier.ashrae_number
          ashrae = "ashrae.#{identifier.ashrae_number}"
          ashrae += "-#{identifier.ashrae_year}" if identifier.ashrae_year
          parts << ashrae
        end

        if identifier.crossref
          parts << "xref.#{identifier.crossref}"
        end

        if identifier.relationships&.any?
          rel = identifier.relationships.join("/")
          parts << "rel.#{rel}"
        end

        if identifier.revision_of
          parts << "revof.#{identifier.revision_of}"
        end

        if identifier.amendment_to
          parts << "amdto.#{identifier.amendment_to}"
        end

        if identifier.adoption
          parts << "adopt.#{identifier.adoption}"
        end

        reaffirmed = maybe(:reaffirmed)
        if reaffirmed
          parts << "reaff.#{reaffirmed}"
        end

        if identifier.note
          parts << "note.#{identifier.note}"
        end

        if identifier.nickname
          parts << "nick.#{identifier.nickname}"
        end

        parts.join(":")
      end

      private

      def special_identifier_type_component
        class_name = identifier.class.name.to_s

        case class_name
        when /RedlinedStandard/
          "redlined"
        when /SiStandard/
          "si"
        when /ConformanceIdentifier/
          "conformance"
        when /InterpretationIdentifier/
          "interpretation"
        when /SupplementIdentifier/
          if identifier.typed_stage
            type_code = identifier.typed_stage.type_code
            case type_code.to_s
            when "amd"
              "amendment"
            when "cor"
              "corrigendum"
            when "errata"
              "errata"
            else
              type_code.to_s
            end
          end
        else
          if identifier.typed_stage
            type_code = identifier.typed_stage.type_code
            case type_code.to_s
            when "SI"
              "si"
            end
          end
        end
      end

      def publisher_component
        pub = identifier.publisher || "IEEE"
        pub = pub.to_s.downcase

        if identifier.copublisher&.any?
          copubs = identifier.copublisher.map(&:to_s).map(&:downcase)
          pub = [pub, *copubs].join("-")
        end

        pub
      end

      def type_component
        return nil unless identifier.type

        type = identifier.type
        return nil if !type || type.to_s.strip.empty? || type.to_s == "Std"

        type.to_s.downcase.gsub(" ", ".")
      end

      def code_component
        return nil unless identifier.code_obj

        identifier.code_obj.to_s
      end

      def draft_component
        return nil unless identifier.draft_obj

        "draft.#{identifier.draft_obj}"
      end

      def edition_component
        return nil unless identifier.edition

        "ed.#{identifier.edition}"
      end

      def month_day_component
        parts = []

        parts << identifier.month if identifier.month
        parts << identifier.day if identifier.day

        return nil if parts.empty?

        parts.join("-")
      end

      def draft_status_component
        return nil unless identifier.draft_status

        status = identifier.draft_status.downcase
        status.gsub(" ", ".")
      end
    end
  end
end
