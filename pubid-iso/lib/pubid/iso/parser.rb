require_relative "identifier/base"
require_relative "renderer/base"

module Pubid::Iso
  class Parser < Pubid::Core::Parser
    STAGES = %w[NP NWIP WD CD FCD PRF AWI PWI FPD].freeze
    TYPES = %w[DATA ISP IWA R TTA TS TR IS PAS Guide GUIDE DIR].freeze
    # TYPED_STAGES = %w[DIS FDIS DPAS FDTR FDTS DTS DTR PDTR PDTS].freeze
    SUPPLEMENTS = %w[Amd Cor AMD COR Suppl].freeze
    STAGED_SUPPLEMENTS = Pubid::Iso::Identifier::Amendment::TYPED_STAGES.map do |_, v|
      v[:legacy_abbr] + [v[:abbr]]
    end.flatten +
      Pubid::Iso::Identifier::Corrigendum::TYPED_STAGES.map do |_, v|
        v[:legacy_abbr] + [v[:abbr]]
      end.flatten +
      Pubid::Iso::Identifier::Supplement::TYPED_STAGES.map do |_, v|
        v[:abbr]
      end.flatten +
      %w[pDCOR PDAM]

    STAGED_ADDENDA = Pubid::Iso::Identifier::Addendum::TYPED_STAGES.map do |_, v|
      v[:abbr]
    end

    DIR_SUPPLEMENTS = %w[Supplement SUP].freeze

    TYPED_STAGES = (Identifier.config.types.map do |type|
      type::TYPED_STAGES.map do |_, v|
        v.key?(:legacy_abbr) ? (v[:legacy_abbr] + [v[:abbr]]) : v[:abbr]
      end
    end.flatten - STAGED_SUPPLEMENTS + %w[PDTR PDTS]).sort_by(&:length).reverse

    TCTYPES = ["TC", "JTC", "PC", "IT", "CAB", "CASCO", "COPOLCO",
      "COUNCIL", "CPSG", "CS", "DEVCO", "GA", "GAAB", "INFCO",
      "ISOlutions", "ITN", "REMCO", "TMB", "TMBG", "WMO",
      "DMT", "JCG", "SGPM", "ATMG", "CCCC", "CCCC-TG", "JDMT",
      "JSAG", "JSCTF-TF", "JTCG", "JTCG-TF", "SAG_Acc", "SAG_CRMI",
      "SAG_CRMI_CG", "SAG_ESG", "SAG_ESG_CG", "SAG_MRS", "SAG SF", "SAG SF_CG",
      "SMCC", "STMG", "MENA STAR"].freeze

    WGTYPES = ["AG", "AHG", "AhG", "WG", "JWG", "QC", "TF",
      "PPC", "CAG", "WG SGDG", "WG SR", "STAR", "STTF", "TIG",
      "CPAG", "CSC", "ITSAG", "CSC/FIN", "CSC/NOM", "CSC/OVE",
      "CSC/SP", "CSC/FIN", "JAG"].freeze

    ORGANIZATIONS = %w[IEC IEEE CIW SAE CIE ASME ASTM OECD ISO HL7 CEI UNDP].freeze
    rule(:dash) do
      str("-") | str("‑") | str("‐")
    end

    rule(:stage) do
      array_to_str(Pubid::Iso::Renderer::Base::TRANSLATION[:russian][:stage].values) | array_to_str(STAGES) |
        (str("preCD") | str("PreCD"))
    end

    rule(:typed_stage) do
      array_to_str(TYPED_STAGES)
    end

    rule(:staged_supplement) do
      array_to_str(STAGED_SUPPLEMENTS)
    end

    rule(:supplements) do
      array_to_str(SUPPLEMENTS)
    end

    rule(:type) do
      (array_to_str(Pubid::Iso::Renderer::Base::TRANSLATION[:russian][:type].values) | array_to_str(TYPES)).as(:type)
    end

    rule(:staged_addenda) do
      array_to_str(STAGED_ADDENDA)
    end

    rule(:tctype) do
      # tc-types
      array_to_str(TCTYPES)
    end

    rule(:sctype) do
      str("SC")
    end

    rule(:wgtype) do
      array_to_str(WGTYPES)
    end

    rule(:roman_numerals) do
      str("CD").absent? >> array_to_str(%w[I V X L C D M]).repeat(1).as(:roman_numerals)
    end

    rule(:year_digits) { (str("19") | str("20")) >> match('\d').repeat(2, 2) >> digits.absent? }

    rule(:part_matcher) do
      year_digits.absent? >>
        supplements.absent? >>
        staged_addenda.absent? >> ((roman_numerals >> digits.absent?) | match['[\dA-Z]'].repeat(1)).as(:part)
    end

    rule(:part) do
      (str("/") | dash) >> space? >> part_matcher >> (dash >> part_matcher).repeat
    end

    rule(:organization) do
      array_to_str(Pubid::Iso::Renderer::Base::TRANSLATION[:russian][:publisher].values) | array_to_str(ORGANIZATIONS)
    end

    rule(:edition) do
      space >> ((str("ED") | str("Ed ") | str("Ed.")) >>
        digits.as(:edition) | str("Ed").as(:edition))
    end

    rule(:iteration) do
      str(".") >> digits.as(:iteration)
    end

    rule(:supplement) do
      ((str("/") | space).maybe >>
        (((stage.as(:typed_stage) >> space).maybe >> supplements.as(:type)) |
          (staged_supplement).as(:typed_stage)) >>
        (space | str(".")).repeat(1).maybe >>
        digits.as(:number).maybe >>
        (str(".") >> digits.as(:iteration)).maybe >>
        ((str(":") | dash) >> digits.as(:year)).maybe).repeat(1).as(:supplements)
    end

    rule(:addendum) do
      (
        (((str("/") >> (str("Add") | str("ADD")).as(:type)) | (str(" — ") >> str("Addendum").as(:type))) |
         (str("/") >> staged_addenda.as(:typed_stage))) >>
          space >> digits.as(:number) >> ((str(":")) >> digits.as(:year)).maybe
      ).repeat(1).as(:supplements)
    end

    rule(:extract) do
      str("/") >> str("Ext") >> space >> (digits.as(:number) >> str(":") >> digits.as(:year)).as(:extract)
    end

    rule(:language) do
      str("(") >> (
        ( # parse ru,en,fr
          (match["a-z"].repeat(1) >> str(",").maybe) |
          # parse R/E/F
          ((str("E") | str("F") | str("A") | str("R")) >> str("/").maybe)
        ).repeat.as(:language)
      ) >> str(")")
    end

    rule(:guide_prefix) do
      str("Guide") | str("GUIDE") | str("Руководство") | str("Руководства")
    end

    # Parse technical committee documents
    rule(:tc_document_body) do
      (tctype.as(:tctype) >> str("/").maybe).repeat >> space >> digits.as(:tcnumber) >>
        (str("/") >> (
          ((sctype.as(:sctype) >> space >> digits.as(:scnumber) >> str("/")).maybe >>
            wgtype.as(:wgtype) >> space >> digits.as(:wgnumber)) |
            (sctype.as(:sctype) >> (space | str("/") >> wgtype.as(:wgtype) >> space) >> digits.as(:scnumber))
        )).maybe >>
        space >> str("N") >> space? >> digits.as(:number)
    end

    rule(:dir_supplement_edition) do
      space >> (str("Edition") | str("Ed")) >> space >> digits.as(:edition)
    end

    rule(:dir_document_body) do
      ((str("DIR") | str("Directives Part") | str("Directives, Part") | str("Directives,")).as(:type) >> space).maybe >>
        (str("JTC").as(:dirtype) >> space).maybe >>
        (digits.as(:number) >> (str(":") >> year).maybe).maybe >>
        (space >> str("DIR").as(:jtc_dir) >> (str(":") >> year).maybe).maybe >>
        (str(" -- Consolidated").maybe >> (str("").as(:mark) >> space? >>
          (organization.as(:publisher) >> space?).maybe >>
          array_to_str(DIR_SUPPLEMENTS) >> (str(":") >> (year >> (dash >> month_digits.as(:month)).maybe)).maybe >>
          dir_supplement_edition.maybe).repeat(1).as(:supplements)).maybe >>
          # parse identifiers with publisher at the end, e.g. "ISO/IEC DIR 2 ISO"
          (space >> organization.as(:publisher) >> (str(":") >> year).maybe).as(:edition).maybe

    end

    rule(:std_document_body) do
      (type | (stage.as(:stage) >> digits.as(:iteration).maybe)).maybe >>
        # for ISO/IEC WD TS 25025
        space? >> ((stage.as(:stage) | typed_stage.as(:stage) | type) >> space).maybe >>
        digits.as(:number) >>
        # for identifiers like ISO 5537/IDF 26
        (str("|") >> (str("IDF").as(:publisher) >> space >> digits.as(:number)).as(:joint_document)).maybe >>
        part.maybe >> iteration.maybe >>
        (space? >> (str(":") | dash) >> year).maybe >>
        supplement.maybe >>
        extract.maybe >>
        addendum.maybe >>
        edition.maybe >>
        language.maybe
    end

    rule(:identifier) do
      str("Fpr").as(:stage).maybe >>
        # Withdrawn e.g: WD/ISO 10360-5:2000
        str("WD/").maybe >>
        # for French and Russian PubIDs starting with Guide type
        (guide_prefix.as(:type) >> space).maybe >>
        (stage.as(:stage) >> space).maybe >>
        (typed_stage.as(:stage) >> space).maybe >>
        (originator >> (space | str("/"))).maybe >>
        (tc_document_body | std_document_body | (dir_document_body >>
          (str(" + ") >> (originator >> space >> dir_document_body).as(:dir_joint_document)).maybe))
    end

    rule(:root) { identifier }
  end
end
