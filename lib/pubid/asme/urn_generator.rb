# frozen_string_literal: true

module Pubid
  module Asme
    class UrnGenerator < Pubid::UrnGenerator::Base
      def generate
        parts = ["urn", "asme"]

        special_type = special_identifier_type_component
        parts << special_type if special_type

        parts << publisher_component

        if identifier.number
          parts << identifier.number.to_s
        end

        part = maybe(:part)
        if part
          p = part.to_s
          parts[-1] = "#{parts[-1]}-#{p}"
        end

        subpart = maybe(:subpart)
        if subpart
          sp = subpart.to_s
          parts[-1] = "#{parts[-1]}-#{sp}"
        end

        if identifier.draft_year
          parts << identifier.draft_year.to_s
        elsif identifier.year
          parts << identifier.year.to_s
        end

        edition = maybe(:edition)
        if edition
          e = edition.number || edition.to_s
          parts << "ed.#{e}"
        end

        if special_type != "ptc" && identifier.ptc_suffix
          parts << "ptc-suffix.#{identifier.ptc_suffix}"
        end

        if special_type != "csa" && identifier.csa_number
          parts << "csa.#{identifier.csa_number}"
        end

        if identifier.first_publisher
          parts << "pub1.#{identifier.first_publisher.to_s.downcase}"
        end

        if identifier.first_code
          parts << "code1.#{identifier.first_code}"
        end

        if identifier.second_publisher
          parts << "pub2.#{identifier.second_publisher.to_s.downcase}"
        end

        if identifier.joint_publisher
          parts << "joint.#{identifier.joint_publisher.to_s.downcase}"
        end

        if identifier.language
          parts << identifier.language.to_s.downcase
        end

        if identifier.reaffirmation
          parts << "reaff.#{identifier.reaffirmation}"
        end

        if identifier.revision_note
          parts << "revnote.#{identifier.revision_note}"
        end

        if identifier.parenthetical_revision
          parts << "prev.#{identifier.parenthetical_revision}"
        end

        languages = maybe(:languages)
        if languages&.any?
          lang_codes = languages.map(&:code).join(",")
          parts << lang_codes
        end

        parts.join(":")
      end

      private

      def special_identifier_type_component
        if identifier.handbook
          return "handbook"
        end

        if identifier.ptc_suffix
          return "ptc"
        end

        if identifier.csa_number
          return "csa"
        end

        class_name = identifier.class.name.to_s
        case class_name
        when /PTC/
          "ptc"
        when /Handbook/
          "handbook"
        end
      end

      def publisher_component
        pub = "asme"

        if identifier.publisher
          p = identifier.publisher.to_s
          pub = p.to_s.downcase
        end

        copubs = maybe(:copublishers)
        if copubs&.any?
          cp = copubs.map(&:to_s)
          pub = "#{pub}-#{cp.join('-').downcase}"
        end

        pub
      end
    end
  end
end
