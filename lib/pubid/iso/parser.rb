require "parslet"
# frozen_string_literal: true

module Pubid
  module Iso
    class Parser < ::Pubid::Parser::Grammar
      include ::Pubid::Parser::CommonParseRules
      include ::Pubid::Parser::CommonParseMethods

      DASH_CHARS = ["-", "‑", "‐"].freeze

      # Supplement identifier type keys (kept as a hard-coded list to match
      # the previous identifier split; only the base identifier registry
      # is auto-discovered from the Identifiers namespace).
      SUPPLEMENT_TYPE_KEYS = %i[amd cor suppl ext add].freeze

      # We need to sort by length to match longest first because that's how Parslet works
      TYPED_STAGES = Pubid::Iso.identifier_types
        .reject { |k| SUPPLEMENT_TYPE_KEYS.include?(k.type[:key]) }
        .flat_map { |k| k.const_defined?(:TYPED_STAGES) ? k.const_get(:TYPED_STAGES) : [] }
        .map(&:abbr).flatten.sort_by(&:length).reverse
      TYPED_STAGES_SUPPLEMENTS = Pubid::Iso.identifier_types
        .select { |k| SUPPLEMENT_TYPE_KEYS.include?(k.type[:key]) }
        .flat_map { |k| k.const_defined?(:TYPED_STAGES) ? k.const_get(:TYPED_STAGES) : [] }
        .map(&:abbr).flatten.sort_by(&:length).reverse

      root :identifier

      # TC documents must come first since they start with "ISO/"
      # and we need to distinguish them from regular ISO/IEC identifiers
      rule(:identifier) do
        bare_tc_document |
          nsb_iso_identifier |
          tc_document |
          directives_identifiers |
          jcgm_identifier |
          iso_r_supplement_identifier |
          iso_r_identifier |
          supplement_supplement_supplement_identifier |
          supplement_supplement_identifier |
          supplement_identifier |
          joint_identifier |
          identifier_copublishers
      end

      # JCGM identifiers (Joint Committee for Guides in Metrology)
      # JCGM 200:2008(F)
      rule(:jcgm_identifier) do
        str("JCGM").as(:publisher) >> space >>
          second_part >> third_part
      end

      # TC Document: ISO/TC 184/SC 4/WG 3 N 123
      #             ISO/TC 184 N 100
      #             ISO/JTC 1 N 456
      #             ISO/TC 184/SC 4 N 789 (TC and SC only, no WG)
      rule(:tc_document) do
        # Accept either "ISO/TC 184…" or the lenient space form "ISO TC 184…"
        # (the latter was valid in pubid 1.x via an optional slash).
        prefix_sole_publisher >> (str("/") | space) >> tc_type >> space >> tc_number.as(:tc_number) >>
          tc_subcommittee_part.maybe >>
          space >> str("N") >> space? >> digits.as(:number) >>
          (str(":") >> year_digits.as(:year)).maybe
      end

      # Bare TC document reference (pubid-iso#285): "184/SC 4/WG 12 N10291"
      # — the ISO/TC route without the ORIGINATOR prefix; the builder
      # canonicalizes the publisher to ISO. The SC segment is required so
      # bare numbers cannot leak into the route.
      rule(:bare_tc_document) do
        digits.as(:tc_number) >>
          str("/") >> sc_type >> space >> digits.as(:sc_number) >>
          (str("/") >> wg_type >> space >> digits.as(:wg_number)).maybe >>
          space >> str("N") >> space? >> digits.as(:number) >>
          (str(":") >> year_digits.as(:year)).maybe
      end

      rule(:tc_subcommittee_part) do
        # Full path: TC/SC 4/WG 3
        (str("/") >> sc_type >> space >> digits.as(:sc_number) >> str("/") >>
          wg_type >> space >> digits.as(:wg_number)) |
          # TC and SC only: TC/SC 4 N 789
          (str("/") >> sc_type >> space >> digits.as(:sc_number))
      end

      rule(:tc_type) do
        array_to_str(Identifiers::TcDocument::TC_TYPES).as(:tc_type)
      end

      rule(:sc_type) do
        # "SC" plus the "SC/QC" quality-committee variant
        # (e.g. ISO/TC 184/SC/QC 4 N 246). Longest first for Parslet.
        (str("SC/QC") | str("SC")).as(:sc_type)
      end

      rule(:wg_type) do
        array_to_str(Identifiers::TcDocument::WG_TYPES).as(:wg_type)
      end

      rule(:tc_number) do
        digits
      end

      # ISO/R 947:1969 (legacy Recommendation without supplement)
      rule(:iso_r_identifier) do
        str("ISO/R").as(:iso_r_prefix) >> space >>
          iso_r_second_part >> third_part
      end

      # ISO/R 947:1969/Add 1:1969 (legacy Recommendation with supplement)
      # Also handles: ISO/R 91-1970 — Addendum 1 (dash for year, em-dash + word)
      rule(:iso_r_supplement_identifier) do
        (
          str("ISO/R").as(:iso_r_prefix) >> space >> iso_r_second_part
        ).as(:base) >>
          iso_r_supplement_separator >>
          supplement_type_with_stage >>
          space? >> second_part >> third_part
      end

      # ISO/R supplements can use "/" or em-dash "—" or " - " as separator
      rule(:iso_r_supplement_separator) do
        str("/") | (space? >> str("—") >> space?) | (space >> str("-") >> space)
      end

      # Special second_part for ISO/R that treats dash as date separator only
      rule(:iso_r_second_part) do
        number.as(:number_with_part) >>
          stage_iteration.maybe >>
          space? >> date.maybe
      end

      # ISO 8601-1:2019
      # ISO/R 947:1969 (legacy Recommendation format)
      rule(:prefix_sole_publisher) do
        (str("ISO") | str("IEC")).as(:publisher)
      end

      # ISO/SAE PAS 22736:2021
      # ISO/R 947:1969 (legacy Recommendation - special handling)
      rule(:prefix_with_copublishers) do
        # Try ISO/R first (must be followed by space + number to avoid confusion with copublishers)
        (str("ISO/R").as(:iso_r_prefix) >> space) |
          # Otherwise normal publisher with optional copublishers
          (prefix_sole_publisher >> space? >> copublishers.maybe)
      end

      ORGANIZATIONS = %w[
        ISO IEC IEEE CIW SAE CIE ASME ASTM OECD ISO HL7 CEI UNDP
      ].freeze
      rule(:copublishers) do
        (str("/") >> space? >> array_to_str(ORGANIZATIONS).as(:copublisher)).repeat.as(:copublishers)
      end

      rule(:number_with_part) do
        (number >> part_and_subpart.maybe).as(:number_with_part)
      end

      rule(:number) do
        match('\d').repeat(1, 5)
      end

      rule(:date) do
        # :2005-02 or :-- (undated reference — ISO/IEC undated-reference form,
        # e.g. ISO 16634:--, also accepted as the em-dash variant ISO 16634:—)
        (str(":") | dash) >>
          (
            (str("--") | str("—")).as(:undated_marker) |
              (year_digits >>
                (dash >> month_digits).maybe >>
                (dash >> day_digits).maybe
              ).as(:date)
          ).maybe
      end

      rule(:part_and_subpart) do
        # Modern parts
        # ISO 105-A01:1989
        # ISO/IEC/IEEE 8802-1AB
        # ISO/IEC TR 29110-5-1-1

        # Legacy parts
        # ISO 31/0-1974
        # ISO 105/F (also known as ISO 105-F)
        # ISO 5843/6 (also known as ISO 5843-6)

        # Modern parts can have subparts using dash
        # the "space?" needed to handle "ISO/TS 10303- 1751:2014"
        (
          dash >> space? >>
          # matches a part
          match('\w').repeat(1) >>
          # matches a subpart, e.g. "A01" or "1-2" (yes we treat {5}-{1-1} as part and subpart)
          (dash >> match('\w').repeat(1)).repeat.maybe
        ) |
          # Legacy parts do not have subparts
          # the "/" to handle old style parts: "ISO 5843/6"
          # Guard: don't match supplement type names (Amd, Cor, Sup, etc.)
          (
            str("/") >> space? >>
            supplement_type_with_stage.absent? >>
            # matches a part
            match('\w').repeat(1)
          )
      end

      rule(:all_parts) do
        str("(all parts)").as(:all_parts)
      end

      rule(:type_with_stage) do
        # "DTR"
        # "PRF PAS"
        # "PRF"
        # "PAS"
        array_to_str(TYPED_STAGES).as(:type_with_stage) >>
          (match('\d').as(:stage_iteration) >> space).maybe
      end

      rule(:language) do
        # ISO 8601-1:2019(en,fr)
        # ISO 8601-1:2019(E/F)
        str("(") >>
          (
            # parse 2-char language codes: ru,en,fr,de,ar,es
            (match["a-z"].repeat(1) >> str(",").maybe) |
            # parse single language codes: R/E/F or R,E,F
            (match["EFARDS"] >> (str("/") | str(",")).maybe)
          ).repeat.as(:languages) >>
          str(")")
      end

      EDITION_STRINGS = %w[Edition Ed. ED Ed].freeze
      rule(:edition) do
        # Capture the entire edition text for exact reproduction
        (array_to_str(EDITION_STRINGS) >> space? >> digits.maybe).as(:edition)
      end

      rule(:stage_iteration) do
        # "ISO 11243.1"
        str(".") >> match('\d').as(:stage_iteration)
      end

      # Modern identifiers use ':' as year identifier, e.g. "ISO 8601-1:2019"
      # Legacy identifiers use '-' as year identifier, e.g. "ISO 31/0-1974"
      rule(:second_part) do
        number_with_part >>
          stage_iteration.maybe >>
          space? >> date.maybe
      end

      rule(:third_part_edition) do
        space? >> edition.maybe
      end

      rule(:third_part) do
        # End of the identifier, we can have language, edition, or all parts
        third_part_edition >> language.maybe >> space? >> all_parts.maybe
      end

      # prefix sole or copublishers with type and stage
      # ISO/WD TR 23642
      # ISO/NP TS 20594-1
      # ISO/PRF PAS 22596
      # ISO/ASTM DTR 52905
      # ISO/IEC WD TS 25025
      #
      ## SUPPORTED ABERRATION: ISO TR 16401-2
      ## SUPPORTED ABERRATION: ISO/IEC/TS 24192-1
      rule(:identifier_copublishers) do
        identifier_copublishers_no_third >> third_part
      end

      # TODO: Support parsing Russian style identifiers
      rule(:guide_prefix) do
        str("Guide") | str("GUIDE") # | str("Руководство") | str("Руководства")
      end

      rule(:identifier_copublishers_no_third) do
        # Guide ISO/CEI 51:1999
        (guide_prefix.as(:type_with_stage_fr) >> space).maybe >>
          # maybe prefix_with_copublishers to handle IWA
          prefix_with_copublishers.maybe >> space? >> str("/").maybe >>
          type_with_stage.maybe >>
          space.maybe >>
          second_part >> third_part_edition
      end

      # For joint identifiers, we do not treat it as a supplementary identifier
      # (hence not a base)
      # ISO only supports IDF in joint identifiers
      # ISO 5537|IDF 26
      # ISO 17678|IDF 202:2010
      # ISO/TS 4985:2023 | IDF/RM 255
      # ISO 4214:2022 | IDF 254:2022
      rule(:joint_identifier) do
        identifier_copublishers_no_third.as(:base) >>
          space? >> str("|") >> space? >>
          scope { idf_identifier }.as(:joint_identifier)
      end

      rule(:idf_identifier) do
        Idf::Parser.new.identifier
      end

      # NSB ISO identifiers - National Body prefixed ISO identifiers
      # FprISO 105-A03
      # FprISO/IEC 17029
      # WD/ISO 10360-2
      # WD/ISO 10360-5:2000
      rule(:nsb_iso_identifier) do
        # FprISO, FprISO/IEC - stage prefix directly attached to publisher
        (str("Fpr").as(:nsb_stage) >>
          prefix_sole_publisher >> space? >> copublishers.maybe >>
          space.maybe >>
          type_with_stage.maybe >>
          space.maybe >>
          second_part >> third_part) |
          # WD/ISO - stage prefix with slash before publisher
          (str("WD").as(:nsb_stage) >> str("/") >>
            prefix_sole_publisher >> space? >> copublishers.maybe >>
            space.maybe >>
            type_with_stage.maybe >>
            space.maybe >>
            second_part >> third_part)
      end

      # TODO: Do something with NSB ISO identifiers like "FprISO", "WD/ISO"
      # Guide ISO/CEI 51:1999
      # FprISO 105-A03
      # FprISO/IEC 17029
      # WD/ISO 10360-5:2000
      # ISO 4918:2016+A1:2018
      # rule(:nsb_iso_identifier) do
      #       str("Fpr").as(:stage).maybe >>
      #         # Withdrawn e.g: WD/ISO 10360-5:2000
      #         str("WD/").maybe >>
      #         # for French and Russian PubIDs starting with Guide type
      #         (guide_prefix.as(:type) >> space).maybe >>
      #         (stage.as(:stage) >> space).maybe >>
      #         (typed_stage.as(:stage) >> space).maybe >>
      #         (originator >> (space | str("/"))).maybe >>
      #         (tc_document_body | std_document_body | (dir_document_body >>
      #           (str(" + ") >> (originator >> space >> dir_document_body).as(:dir_joint_document)).maybe))
      # end

      rule(:supplement_type_with_stage) do
        # "DAM"
        # "NP Amd"
        array_to_str(TYPED_STAGES_SUPPLEMENTS).as(:type_with_stage)
      end

      # ISO 8601-1:2019/Amd 2:2024
      # ISO/IEC 10646-1:1993/pDCOR.2 (legacy dot-prefixed format)
      rule(:supplement_identifier_no_third) do
        identifier_copublishers_no_third.as(:base) >>
          str("/") >> supplement_type_with_stage >>
          # The trailing number/date is optional: some draft supplements have no
          # number yet, e.g. "ISO/IEC 9579/WD Amd".
          ((space? >> second_part) | (str(".") >> digits.as(:number)) | (space? >> date)).maybe
      end

      rule(:supplement_identifier) do
        supplement_identifier_no_third >> third_part
      end

      # ISO/IEC 13818-1:2015/Amd 3:2016/Cor 1:2017
      # ISO/IEC 19794-7:2014/Amd 1:2015/CD Cor 1
      # ISO/IEC 10646-1:1993/pDCOR.2 (legacy dot-prefixed format)
      rule(:supplement_supplement_identifier) do
        supplement_identifier_no_third.as(:base) >>
          str("/") >> supplement_type_with_stage >>
          ((space? >> second_part >> third_part) | (str(".") >> digits.as(:number) >> third_part))
      end

      # ISO 12345:2020/Amd 1:2021/Cor 1:2022/Amd 2:2023 (three-level supplement)
      rule(:supplement_supplement_supplement_identifier) do
        supplement_supplement_identifier.as(:base) >>
          str("/") >> supplement_type_with_stage >>
          ((space? >> second_part >> third_part) | (str(".") >> digits.as(:number) >> third_part))
      end

      # ISO/IEC DIR
      # ISO/IEC DIR 1
      # ISO/IEC DIR 2:2022
      rule(:directives_identifier) do
        directives_identifier_no_third >> third_part.maybe >> space? >> date.maybe
      end

      # ISO/IEC JTC 1 DIR (JTC 1 Directives)
      rule(:directives_publisher_subgroup) do
        str("JTC 1").as(:subgroup)
      end

      # Special number_with_part rule for Directives to handle variants
      # We treat the variant as `part` of the number_with_part
      rule(:directives_number_with_part) do
        (number >> directives_part_and_subpart.maybe).as(:number_with_part)
      end

      # ISO/IEC DIR 1 IEC (IEC version of the ISO/IEC DIR 1)
      # ISO/IEC DIR 2 ISO:2022 (ISO version of the ISO/IEC DIR 2)
      # But NOT: ISO/IEC DIR 1 ISO SUP:2022 (ISO is supplement publisher)
      # "1 IEC"
      # "2 ISO"
      rule(:directives_part_and_subpart) do
        # Only match ISO/IEC if NOT followed by "/" (dual publisher) or supplement keywords
        space >> (str("ISO") | str("IEC")) >> str("/").absent? >> (space >> str("SUP")).absent?
      end

      DIRECTIVES_TYPED_STAGES = Identifiers::Directives::TYPED_STAGES.map(&:abbr).flatten.sort_by(&:length).reverse
      rule(:directives_identifier_no_third) do
        prefix_with_copublishers >> space? >>
          (directives_publisher_subgroup >> space).maybe >>
          array_to_str(DIRECTIVES_TYPED_STAGES).as(:type_with_stage) >>
          # The subgroup may also follow the type, e.g. "ISO/IEC DIR JTC 1"
          # (canonical form is "ISO/IEC JTC 1 DIR"). Guard against a trailing
          # supplement, where "JTC 1" is the supplement publisher instead
          # (e.g. "ISO/IEC DIR JTC 1 SUP").
          (space >> directives_publisher_subgroup >> (space >> str("SUP")).absent?).maybe >>
          (
            (space >> directives_number_with_part).maybe >>
            (str(":") >> date).maybe
          ).maybe
      end

      rule(:directives_supplement_identifier) do
        directives_identifier_no_third.as(:base) >> space? >> directives_supplement_part
      end

      DIRECTIVES_SUPPLEMENTS_TYPED_STAGES = Identifiers::DirectivesSupplement::TYPED_STAGES.map(&:abbr).flatten.sort_by(&:length).reverse

      rule(:directives_supplement_part_no_third) do
        # ISO/IEC DIR 1 ISO SUP
        # ISO/IEC DIR 2 ISO SUP:2022
        # ISO/IEC DIR JTC 1 SUP:2021
        # ISO/IEC Directives, Part 1 -- Consolidated ISO Supplement
        (space? >> str("--") >> space? >> str("Consolidated") >> space).maybe >>
          (str("ISO/IEC") | str("ISO") | str("IEC") | str("JTC 1")).as(:publisher) >>
          (space >> array_to_str(DIRECTIVES_SUPPLEMENTS_TYPED_STAGES).as(:type_with_stage)) >>
          date.maybe
      end

      rule(:directives_supplement_part) do
        directives_supplement_part_no_third >> third_part.maybe
      end

      # ISO/IEC DIR 1 + IEC SUP:2016-05
      # ISO/IEC DIR 1:2022 + IEC SUP:2022
      rule(:directives_bundled_identifier) do
        (
          directives_identifier_no_third >>
          (third_part >> space?).maybe >>
          (date >> space?).maybe
        ).as(:base_document) >>
          (
            str("+ ") >>
            directives_supplement_part_no_third.as(:supplement)
          ).repeat(1).as(:supplements)
      end

      rule(:directives_identifiers) do
        directives_bundled_identifier |
          directives_supplement_identifier |
          directives_identifier
      end

      rule(:dash) do
        DASH_CHARS.map { |char| str(char) }.reduce(:|)
      end

      #     rule(:tctype) do
      #       # tc-types
      #       array_to_str(TCTYPES)
      #     end

      #     rule(:sctype) do
      #       str("SC")
      #     end

      #     rule(:wgtype) do
      #       array_to_str(WGTYPES)
      #     end

      #     rule(:roman_numerals) do
      #       str("CD").absent? >> array_to_str(%w[I V X L C D M]).repeat(1).as(:roman_numerals)
      #     end

      #     rule(:part_matcher) do
      #       year_digits.absent? >>
      #         supplements.absent? >>
      #         staged_addenda.absent? >> ((roman_numerals >> digits.absent?) | match['[\dA-Z]'].repeat(1)).as(:part)
      #     end

      #     rule(:supplement) do
      #       ((str("/") | space).maybe >>
      #         (((stage.as(:typed_stage) >> space).maybe >> supplements.as(:type)) |
      #           staged_supplement.as(:typed_stage)) >>
      #         (space | str(".")).repeat(1).maybe >>
      #         digits.as(:number).maybe >>
      #         (str(".") >> digits.as(:iteration)).maybe >>
      #         ((str(":") | dash) >> digits.as(:year)).maybe).repeat(1).as(:supplements)
      #     end

      # # Parse technical committee documents
      # rule(:tc_document_body) do
      #   (tctype.as(:tctype) >> str("/").maybe).repeat >> space >> digits.as(:tcnumber) >>
      #     (str("/") >> (
      #       ((sctype.as(:sctype) >> space >> digits.as(:scnumber) >> str("/")).maybe >>
      #         wgtype.as(:wgtype) >> space >> digits.as(:wgnumber)) |
      #         (sctype.as(:sctype) >> (space | str("/") >> wgtype.as(:wgtype) >> space) >> digits.as(:scnumber))
      #     )).maybe >>
      #     space >> str("N") >> space? >> digits.as(:number)
      # end

      # rule(:dir_supplement_edition) do
      #   space >> (str("Edition") | str("Ed")) >> space >> digits.as(:edition)
      # end

      # rule(:dir_document_body) do
      #   ((str("DIR") | str("Directives Part") | str("Directives, Part") | str("Directives,")).as(:type) >> space).maybe >>
      #     (str("JTC").as(:dirtype) >> space).maybe >>
      #     (digits.as(:number) >> (str(":") >> year).maybe).maybe >>
      #     (space >> str("DIR").as(:jtc_dir) >> (str(":") >> year).maybe).maybe >>
      #     (str(" -- Consolidated").maybe >> (str("").as(:mark) >> space? >>
      #       (organization.as(:publisher) >> space?).maybe >>
      #       array_to_str(DIR_SUPPLEMENTS) >> (str(":") >> (year >> (dash >> month_digits.as(:month)).maybe)).maybe >>
      #       dir_supplement_edition.maybe).repeat(1).as(:supplements)).maybe >>
      #       # parse identifiers with publisher at the end, e.g. "ISO/IEC DIR 2 ISO"
      #     (space >> organization.as(:publisher) >> (str(":") >> year).maybe).as(:edition).maybe
      # end

      #     rule(:identifier) do
      #       str("Fpr").as(:stage).maybe >>
      #         # Withdrawn e.g: WD/ISO 10360-5:2000
      #         str("WD/").maybe >>
      #         # for French and Russian PubIDs starting with Guide type
      #         (guide_prefix.as(:type) >> space).maybe >>
      #         (stage.as(:stage) >> space).maybe >>
      #         (typed_stage.as(:stage) >> space).maybe >>
      #         (originator >> (space | str("/"))).maybe >>
      #         (tc_document_body | std_document_body | (dir_document_body >>
      #           (str(" + ") >> (originator >> space >> dir_document_body).as(:dir_joint_document)).maybe))
      #     end
    end
  end
end
