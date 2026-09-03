# frozen_string_literal: true

module Pubid
  module Asme
    class Builder
      def build(parsed_hash)
        identifier = Identifiers::Standard.new

        # Handle joint publishers
        if parsed_hash[:joint_publisher]
          identifier.joint_publisher = parsed_hash[:joint_publisher].to_s
          identifier.publisher = parsed_hash[:joint_publisher].to_s
        elsif parsed_hash[:first_publisher]
          # CSA/ASME or API/ASME format
          identifier.first_publisher = parsed_hash[:first_publisher].to_s
          identifier.first_code = parsed_hash[:first_code].to_s
          identifier.second_publisher = parsed_hash[:second_publisher].to_s
          identifier.publisher = "#{parsed_hash[:first_publisher]}/#{parsed_hash[:second_publisher]}"
        else
          # Standard ASME
          identifier.publisher = "ASME"
        end

        # The code is stored as flat index columns on the leaf (see
        # Identifiers::Standard) — `number` is what relaton-index keys on — so
        # the Code built below is unpacked rather than assigned.
        if parsed_hash[:designator]
          identifier.number = build_code(parsed_hash).to_s
        elsif parsed_hash[:number]
          # A joint-published reference ("ISO/ASME 14414-2015") parses to a bare
          # `number` with no designator. The designator-only guard above dropped
          # it, so the document number was lost from BOTH the identifier and its
          # rendering: `to_s` was "ISO/ASME-2015". Pre-existing; recovering it
          # is what gives these ids an index key.
          identifier.number = parsed_hash[:number].to_s
        end

        # Set PTC suffix
        if parsed_hash[:ptc_suffix]
          identifier.ptc_suffix = parsed_hash[:ptc_suffix].to_s
        end

        # Set year
        if parsed_hash[:year]
          identifier.year = parsed_hash[:year].to_s
        end

        # Set draft year
        if parsed_hash[:draft_year]
          identifier.draft_year = parsed_hash[:draft_year].to_s
        end

        # Set reaffirmation
        if parsed_hash[:reaffirmation]
          identifier.reaffirmation = "R#{parsed_hash[:reaffirmation]}"
        end

        # Set language (including lang_suffix from BPVC)
        if parsed_hash[:language]
          identifier.language = parsed_hash[:language].to_s
        elsif parsed_hash[:lang_suffix]
          identifier.language = parsed_hash[:lang_suffix].to_s
        end

        # Set CSA number (for ASME/CSA format)
        if parsed_hash[:csa_number]
          identifier.csa_number = parsed_hash[:csa_number].to_s
        end

        # Set handbook flag
        if parsed_hash[:handbook]
          identifier.handbook = true
        end

        # Set revision note
        if parsed_hash[:revision_note]
          identifier.revision_note = "[#{parsed_hash[:revision_note]}]"
        end

        # Set parenthetical revision
        if parsed_hash[:ref_standard]
          # Extract the type of revision (Revision/Proposed revision)
          ref = parsed_hash[:ref_standard].to_s
          if parsed_hash[:ref_standard].to_s =~ /^(Proposed revision|Revision) of (.+)$/
            identifier.parenthetical_revision = "(#{$1} of #{$2})"
          else
            identifier.parenthetical_revision = "(Revision of #{ref})"
          end
        end

        identifier
      end

      private

      def build_code(parsed_hash)
        # Handle BPVC subdivision
        if parsed_hash[:designator].is_a?(Hash) && parsed_hash[:designator][:bpvc_code]
          bpvc_data = parsed_hash[:designator][:bpvc_code]

          # Build BPVC designator string
          designator_str = "BPVC"

          if bpvc_data[:special]
            # BPVC COMPLETE CODE BIND
            designator_str = "BPVC COMPLETE CODE BIND"
          elsif bpvc_data[:subdivision] && bpvc_data[:subdivision][:ssc_code]
            # BPVC.SSC.XI.II.V.IX pattern
            ssc_sections = bpvc_data[:subdivision][:ssc_sections]
            sections_str = if ssc_sections.is_a?(Array)
                             ssc_sections.join(".")
                           else
                             ssc_sections.to_s
                           end
            designator_str = "BPVC.SSC.#{sections_str}"
          elsif bpvc_data[:subdivision] && bpvc_data[:subdivision][:case_code]
            # BPVC.CC.BPV or BPVC.CC.NC.XI - extract from subdivision hash
            cc = bpvc_data[:subdivision][:case_code].to_s
            case_sub = bpvc_data[:subdivision][:case_sub]&.to_s

            designator_str = case_sub && !case_sub.empty? ? "BPVC.CC.#{cc}.#{case_sub}" : "BPVC.CC.#{cc}"
          elsif bpvc_data[:case_code]
            # Dash notation: BPVC-CC-BPV
            cc = bpvc_data[:case_code].to_s
            designator_str = "BPVC-CC-#{cc}"
          elsif bpvc_data[:subdivision]
            # Standard subdivision
            section = bpvc_data[:subdivision][:section].to_s
            subsection = bpvc_data[:subdivision][:subsection].to_s
            sub_subsection = bpvc_data[:subdivision][:sub_subsection].to_s
            lang_suffix = bpvc_data[:subdivision][:lang_suffix].to_s

            parts = [section, subsection, sub_subsection].reject do |p|
              p.nil? || p.empty?
            end
            designator_str = "BPVC.#{parts.join('.')}"
            designator_str += "_#{lang_suffix}" if !lang_suffix.empty?
          else
            # Fallback (shouldn't reach here)
            designator_str = "BPVC"
          end
          number_str = ""

          return Components::Code.new(designator: designator_str,
                                      number: number_str)
        end

        # For joint published, handle special cases
        designator_str = parsed_hash[:designator].to_s

        # Normalize "V V" to "V&V"
        designator_str = "V&V" if designator_str == "V V"

        # Existing code for non-BPVC designators
        code = Components::Code.new
        code.designator = designator_str
        code.number = parsed_hash[:number].to_s if parsed_hash[:number]
        code
      end
    end
  end
end
