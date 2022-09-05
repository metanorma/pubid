module Pubid::Iso
  class Parser < Pubid::Core::Parser
    STAGES = %w[NP NWIP WD CD DIS FDIS PRF IS AWI PWI FPD pD PD FD D F].freeze
    TYPES = %w[DATA ISP IWA R TTA TS TR PAS Guide GUIDE].freeze

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

    ORGANIZATIONS = %w[IEC IEEE CIW SAE CIE ASME ASTM OECD ISO IWA HL7 CEI].freeze
    rule(:stage) do
      array_to_str(Renderer::Russian::STAGE.values) | array_to_str(STAGES)
    end

    rule(:type) do
      (array_to_str(Renderer::Russian::TYPE.values) | array_to_str(TYPES)).as(:type)
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

    rule(:part) do
      (str("-") | str("/")) >> space? >>
        (str("Amd") | str("Cor")).absent? >> (match['[\dA-Z]'] | str("-")).repeat(1).as(:part)
    end

    rule(:organization) do
      array_to_str(Renderer::Russian::PUBLISHER.values) | array_to_str(ORGANIZATIONS)
    end

    rule(:edition) do
      space >> ((str("ED") | str("Ed ") | str("Ed.")) >>
        digits.as(:edition) | str("Ed").as(:edition))
    end

    rule(:iteration) do
      str(".") >> digits.as(:iteration)
    end

    rule(:amendment) do
      ((str("/") >> stage.as(:stage)).maybe >>
      (str("/") | space).maybe >>
        (str("Amd") | str("AMD") | str("AM")) >>
        (space | str(".")).repeat(1).maybe >>
        digits.as(:number) >>
        (str(".") >> digits.as(:iteration)).maybe >>
        ((str(":") | str("-")) >> digits.as(:year)).maybe).as(:amendments)
    end

    rule(:corrigendum) do
      ((str("/") >> stage.as(:stage)).maybe >>
      (str("/") | space).maybe >>
        (str("Cor") | str("COR")) >>
        (space | str(".")).repeat(1).maybe >>
        digits.as(:number) >>
        (str(".") >> digits.as(:iteration)).maybe >>
        ((str(":") | str("-")) >> digits.as(:year)).maybe).as(:corrigendums)
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
      ((str("DIR") | str("Directives Part") | str("Directives, Part") | str("Directives,")).as(:dir) >> space).maybe >>
        (str("JTC").as(:dirtype) >> space).maybe >>
        (digits.as(:number) >> (str(":") >> year).maybe).maybe >>
        (str(" -- Consolidated").maybe >> (space? >> (organization.as(:publisher) >> space).maybe >>
          (str("SUP") | str("Supplement")) >> (str(":") >> year).maybe >>
          dir_supplement_edition.maybe).as(:supplement)).maybe
    end

    rule(:std_document_body) do
      (type | stage.as(:stage)).maybe >>
        # for ISO/IEC WD TS 25025
        space? >> ((stage.as(:stage) | type) >> space).maybe >>
        digits.as(:number) >>
        # for identifiers like ISO 5537/IDF 26
        (str("|") >> (str("IDF").as(:publisher) >> space >> digits.as(:number)).as(:joint_document)).maybe >>
        part.maybe >> iteration.maybe >>
        (space? >> (str(":") | str("-")) >> year).maybe >>
        # stage before amendment
        (
          # stage before corrigendum
          ((amendment >> corrigendum.maybe) | corrigendum).maybe) >>
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
        originator >> (space | str("/")) >>
        (tc_document_body | std_document_body | (dir_document_body >>
          (str(" + ") >> (originator >> space >> dir_document_body).as(:joint_document)).maybe))
    end

    rule(:root) { identifier }
  end
end
