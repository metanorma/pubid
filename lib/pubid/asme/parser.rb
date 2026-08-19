# frozen_string_literal: true

require "parslet"

module Pubid
  module Asme
    class Parser < Parslet::Parser
      # Basic building blocks
      rule(:space) { str(" ") }
      # Regular dash, en-dash, em-dash
      rule(:dash) do
        str("-") | str("–") | str("—")
      end
      rule(:slash) { str("/") }
      rule(:dot) { str(".") }
      rule(:digit) { match("[0-9]") }
      rule(:digits) { digit.repeat(1) }
      rule(:letter) { match("[A-Z]") }
      rule(:letters) { letter.repeat(1) }
      rule(:underscore) { str("_") }

      # Roman numerals (longest first for proper matching - added X)
      rule(:roman_numeral) do
        str("XIII") | str("XII") | str("XI") | str("VIII") |
          str("VII") | str("VI") | str("IV") | str("IX") | str("X") |
          str("III") | str("II") | str("V") | str("I")
      end

      # BPVC special letter codes
      rule(:bpvc_letter_code) do
        str("NCA") | str("NCD") | str("SSC") | str("BPV") | str("NUC") |
          str("NB") | str("NC") | str("ND") | str("NE") | str("NF") | str("NG") |
          letter # Single letter for A, B, C, D, M
      end

      # BPVC complete subdivision
      rule(:bpvc_subdivision) do
        str("BPVC") >>
          (
            # Special: COMPLETE CODE BIND
            (space >> str("COMPLETE CODE BIND")).as(:special) |
            # Dash notation: BPVC-CC-BPV
            (dash >> str("CC") >> dash >> bpvc_letter_code.as(:case_code)) |
            # Standard dotted notation
            (
              dot >>
              (
                # SSC with complex subdivision: BPVC.SSC.XI.II.V.IX
                (str("SSC") >> (dot >> roman_numeral).repeat(0).as(:ssc_sections)).as(:ssc_code) |
                # CC = Case Code: BPVC.CC.BPV or BPVC.CC.NC.XI
                (str("CC") >> dot >> bpvc_letter_code.as(:case_code) >>
                 (dot >> (roman_numeral | bpvc_letter_code)).maybe.as(:case_sub)) |
                # Standard roman numeral subdivision: BPVC.I or BPVC.III.1.NB
                (roman_numeral.as(:section) >>
                 (dot >> (digits | bpvc_letter_code).as(:subsection)).maybe >>
                 (dot >> bpvc_letter_code.as(:sub_subsection)).maybe >>
                 # Language suffix with underscore: _ES
                 (underscore >> letters.as(:lang_suffix)).maybe)
              )
            ).as(:subdivision)
          ).as(:bpvc_code)
      end

      # Multi-character designator codes (updated with EA)
      rule(:multi_char_code) do
        str("PVHO") | str("PASE") | str("PTC") | str("PTB") | str("PDS") | str("PCC") |
          str("V&V") | str("V V") | # Both ampersand and space variants
          str("VVUQ") |  # Additional V&V variant
          str("TDP") | str("RTP") | str("RT") |
          str("RA-S") |  # New: RA-S with dash
          str("RA") |
          str("QME") | str("QAI") | str("QEI") |
          str("NUM") | str("NQA") | str("NML") |
          str("OM") |
          str("HST") | str("HRT") |
          str("FFS") |
          str("TES") |
          str("TR") | # Keep TR separate for space-separated pattern
          str("STS") | # New: STS-1
          str("CSD") | str("CA") |
          str("BTH") | str("BPE") |
          str("ANDE") | str("AED") |
          str("AG") |
          str("NM") |  # New: NM.1, NM.2, NM.3
          str("EA")    # New: EA-3
      end

      # Publisher patterns
      rule(:asme_publisher) { str("ASME") }
      rule(:csa_publisher) { str("CSA") }
      rule(:api_publisher) { str("API") }
      rule(:iso_publisher) { str("ISO") }
      rule(:ans_publisher) { str("ANS") }

      # Joint publisher patterns
      rule(:iso_asme_publisher) do
        str("ISO/ASME").as(:joint_publisher) >> space.maybe
      end

      rule(:asme_ans_publisher) do
        str("ASME/ANS").as(:joint_publisher) >> space
      end

      rule(:csa_asme_publisher) do
        csa_publisher.as(:first_publisher) >> space >>
          match("[A-Z0-9.]").repeat(1).as(:first_code) >>
          space.maybe >> slash >> asme_publisher.as(:second_publisher) >> space
      end

      rule(:api_asme_publisher) do
        api_publisher.as(:first_publisher) >> space >>
          match("[0-9-]").repeat(1).as(:first_code) >>
          space.maybe >> slash >> asme_publisher.as(:second_publisher) >> space
      end

      # Standard ASME publisher
      rule(:publisher) { asme_publisher >> space }

      # Designator (longest match first!)
      rule(:designator) do
        (
          bpvc_subdivision |      # Try BPVC patterns first
          multi_char_code |       # Multi-char codes BEFORE letters
          str("ISO") |
          str("CSA") |
          str("API") |
          str("ANS") |
          letters                 # Fallback for single-letter
        ).as(:designator)
      end

      # Number part - can start with dot (NM.1), be dotted (16.5), OR dash-separated (BTH-1)
      rule(:number_part) do
        (
          # Starting with dot (for NM.1, VVUQ 20.1, etc.)
          (dot >> match("[0-9A-Z]").repeat(1) >>
           (dot >> match("[0-9A-Z]").repeat(1)).repeat) |
          # Dash-separated first (for BTH-1, CA-1 patterns)
          (dash >> match("[0-9A-Z]").repeat(1) >>
           (dot >> match("[0-9A-Z]").repeat(1)).repeat) |
          # Regular dotted numbers
          (match("[0-9A-Z]").repeat(1) >>
           (dot >> match("[0-9A-Z]").repeat(1)).repeat)
        ).as(:number)
      end

      # PTC special: space-separated number with optional suffix
      rule(:ptc_number) do
        space.maybe >>
          (
            match("[0-9]").repeat(1) >>
            (dot >> match("[0-9]").repeat(1)).repeat
          ).as(:number) >>
          # Optional space + suffix (like "TW" or "PM")
          (space >> letters.as(:ptc_suffix)).maybe
      end

      # TR special: space-separated number (like "ASME TR A17.1-8.4-2013")
      rule(:tr_number) do
        space.maybe >>
          (
            match("[A-Z0-9]").repeat(1) >>
            (dot >> match("[0-9A-Z]").repeat(1)).repeat >>
            # Allow dash for patterns like A17.1-8.4
            (dash >> match("[0-9]").repeat(1) >>
             (dot >> match("[0-9]").repeat(1)).repeat).maybe
          ).as(:number)
      end

      # Number with optional preceding space (for V V 10, V&V 10, VVUQ 20.1, etc.)
      rule(:spaced_number_part) do
        space.maybe >> number_part
      end

      # Year (4-digit)
      rule(:year_4digit) { digit.repeat(4, 4).as(:year) }

      # Draft year patterns: 20XX, 202X
      rule(:draft_year) do
        (str("20XX") | str("202X") | (str("20") >> digit >> str("X"))).as(:draft_year)
      end

      # Reaffirmation notation
      rule(:reaffirmation) do
        space >> str("(R") >> year_4digit.as(:reaffirmation) >> str(")")
      end

      # CSA dual-published number (for ASME/CSA format)
      rule(:csa_portion) do
        slash >> str("CSA") >> space >>
          (letter >> match("[0-9.]").repeat(1)).as(:csa_number)
      end

      # Parenthetical revision note after year - different from [Draft ...] notation
      rule(:parenthetical_revision) do
        space >> str("(") >>
          (str("Proposed revision of") | str("Revision of")) >>
          space >> match("[^)]").repeat(1).as(:ref_standard) >>
          str(")")
      end

      # Revision note [Draft Proposed Revision of ...]
      rule(:revision_note) do
        space >> str("[") >> match("[^\\]]").repeat(1).as(:revision_note) >> str("]")
      end

      # Language notation - support both before and after year
      rule(:language) do
        space >> str("(") >> letters.as(:language) >> str(")")
      end

      # Handbook keyword
      rule(:handbook_keyword) do
        (space >> str("Handbook")).as(:handbook)
      end

      # Standard identifier components
      rule(:standard_components) do
        publisher >>
          designator >>
          number_part.maybe >>
          (csa_portion | handbook_keyword).maybe >>
          # Language can come before or after year
          language.maybe >>
          (
            dash >> (draft_year | year_4digit)
          ).maybe >>
          language.maybe >>
          reaffirmation.maybe >>
          revision_note.maybe
      end

      # Joint published identifier - CSA first
      rule(:csa_asme_identifier) do
        csa_asme_publisher >>
          designator >>
          number_part.maybe >>
          (dash >> (draft_year | year_4digit)).maybe >>
          language.maybe >>
          reaffirmation.maybe
      end

      # Joint published identifier - API first
      rule(:api_asme_identifier) do
        api_asme_publisher >>
          designator >>
          number_part.maybe >>
          (dash >> (draft_year | year_4digit)).maybe >>
          language.maybe >>
          reaffirmation.maybe
      end

      # Joint published identifier - ISO/ASME
      rule(:iso_asme_identifier) do
        iso_asme_publisher >>
          # Year may precede the number ("ISO/ASME-2015") or follow it
          (dash >> (draft_year | year_4digit)).maybe >>
          number_part.maybe >>
          (dash >> (draft_year | year_4digit)).maybe >>
          language.maybe >>
          reaffirmation.maybe
      end

      # Joint published identifier - ASME/ANS
      rule(:asme_ans_identifier) do
        asme_ans_publisher >>
          designator >>
          number_part.maybe >>
          (dash >> (draft_year | year_4digit)).maybe >>
          language.maybe >>
          reaffirmation.maybe
      end

      # Standard ASME identifier
      rule(:standard) do
        publisher >>
          (
            # Year-only form (e.g. "ISO/ASME-2015")
            ((dash >> (draft_year | year_4digit))) |
            # Special case for PTC with space-separated number
            (str("PTC").as(:designator) >> ptc_number >>
             (dash >> (draft_year | year_4digit)).maybe) |
            # Special case for TR with space-separated number
            (str("TR").as(:designator) >> tr_number >>
             (dash >> (draft_year | year_4digit)).maybe) |
            # Regular pattern with designator + optional spaced number
            (designator >> (dash >> year_4digit).maybe >> spaced_number_part.maybe >>
             # CSA portion can be followed by handbook keyword
             ((csa_portion >> handbook_keyword.maybe) | handbook_keyword).maybe >>
             # Language can come before or after year
             language.maybe >>
             (dash >> (draft_year | year_4digit)).maybe >>
             language.maybe)
          ) >>
          # Parenthetical revision note (after year)
          parenthetical_revision.maybe >>
          reaffirmation.maybe >>
          revision_note.maybe
      end

      rule(:identifier) do
        csa_asme_identifier |
          api_asme_identifier |
          iso_asme_identifier |
          asme_ans_identifier |
          standard
      end

      root(:identifier)
    end
  end
end
