# frozen_string_literal: true

module Pubid
  module Evs
    # Parses `urn:evs:…` URNs back into identifiers, following the same
    # pattern as Pubid::CenCenelec::UrnParser: reassemble the identifier's
    # human text and delegate to the real grammar so every structural check
    # happens in parsers, not in this class.
    #
    #   urn:evs:en:18216:2026                → EVS-EN 18216:2026
    #   urn:evs:en:iso:14001:2026            → EVS-EN ISO 14001:2026
    #   urn:evs:en:iso-iec:27017:2026        → EVS-EN ISO/IEC 27017:2026
    #   urn:evs:en:iso:9001:2015:amd:1:2024  → EVS-EN ISO 9001:2015/A1:2024
    #   urn:evs:iso:9001:2015                → EVS-ISO 9001:2015
    #   urn:evs:921:2019                     → EVS 921:2019
    #   urn:evs:ts:1:2019                    → EVS-TS 1:2019
    #   urn:evs:pr:en:100:2026               → prEVS-EN 100:2026
    #   urn:evs:en:1993-1-1:2005:na:2010:et  → EVS-EN 1993-1-1:2005+NA:2010 et
    class UrnParser < Pubid::UrnParser::Base
      ORGS = {
        "iso" => "ISO",
        "iso-iec" => "ISO/IEC",
        "iec" => "IEC",
        "cispr" => "CISPR",
      }.freeze

      TYPES = { "ts" => "TS", "tr" => "TR" }.freeze

      # UrnGenerator emits "urn:evs:" (national-body namespace).
      def flavor_name
        "evs"
      end

      def parse_urn(urn)
        parts = split_parts(strip_namespace(urn))

        draft = parts.first == "pr"
        parts.shift if draft

        # The trailing language code and the EVS-level national annex peel
        # before the body dispatch — both are EVS-level, never cen segments.
        language = parts.last&.match?(/\A(et-en|et|en)\z/) && parts.length > 1 ? parts.pop : nil
        na_year = nil
        na_present = false
        if (na_i = parts.index("na"))
          parts.delete_at(na_i)
          na_present = true
          na_year = parts[na_i]&.match?(/\A\d{4}\z/) ? parts.delete_at(na_i) : nil
        end

        head = parts.shift
        text = +"EVS"

        case head
        when /\Aen\z/i
          # the adopted CEN identifier: "en [org] number[:year] [supplements]"
          text << "-EN"
          org_parts = []
          org_parts << parts.shift while parts.first&.match?(/\A[a-z][a-z-]*\z/)
          if org_parts.any?
            org = ORGS.fetch(org_parts.join("-")) do
              raise Errors::ParseError, "unknown adopted org in #{urn.inspect}"
            end
            text << " #{org}"
          end
          number = parts.shift
          raise Errors::ParseError, "missing number in #{urn.inspect}" unless number

          text << " #{number}"
          year = parts.shift
          text << ":#{year}" if year
          text << adopted_supplement(parts, urn)
        when "ts", "tr"
          number = parts.shift
          year = parts.shift
          text << "-#{TYPES.fetch(head)} #{number}"
          text << ":#{year}" if year
        when "iso", "iec", "cispr"
          # a direct ISO/IEC adoption: "iso:9001[:part]:year"
          org = ORGS.fetch(head)
          number = parts.shift
          part = parts.shift if parts.first&.match?(/\A\d+\z/) && !parts.first&.match?(/\A\d{4}\z/) && parts.length > 1
          year = parts.shift
          text << "-#{org} #{number}"
          text << "-#{part}" if part
          text << ":#{year}" if year
        when /\A\d/
          number = head
          year = parts.shift
          text << " #{number}"
          text << ":#{year}" if year
        else
          raise Errors::ParseError, "unsupported shape in #{urn.inspect}"
        end

        raise Errors::ParseError, "trailing segments in #{urn.inspect}" unless parts.empty?

        if na_present
          text << "+NA"
          text << ":#{na_year}" if na_year
        end
        text << " #{language}" if language

        built = Pubid::Evs.parse(text)
        built.draft_prefix = draft
        built
      end

      private

      # The adopted CEN spine consumes its own supplements; their urn
      # segments carry the consolidation marker ("plus" = "+A1", its absence
      # = "/A1") — cen_cenelec/urn_generator.rb's supplement_segments.
      def adopted_supplement(parts, urn)
        faces = +""
        while %w[plus slash amd cor frag].include?(parts.first)
          if %w[plus slash].include?(parts.first)
            sep = parts.shift == "plus" ? "+" : "/"
            kind = parts.shift
          else
            sep = "/"
            kind = parts.shift
          end
          num = parts.first&.match?(/\A\d{1,3}\z/) ? parts.shift : nil
          yr = parts.first&.match?(/\A\d{4}\z/) ? parts.shift : nil
          faces << case kind
                   when "amd" then "#{sep}A#{num}#{":#{yr}" if yr}"
                   when "cor" then "#{sep}AC#{num}#{":#{yr}" if yr}"
                   else " FRAG#{num}"
                   end
        end
        faces
      end

    end
  end
end
