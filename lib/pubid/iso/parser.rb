module Pubid::Iso
  class Parser < Pubid::Core::Parser
    rule(:stage) do
      Renderer::Russian::STAGE.values.reduce(
        # other stages
        str("NP") | str("WD") | str("CD") | str("DIS") | str("FDIS") | str("PRF") |
        str("IS") | str("AWI") | str("PWI") |
        # AMD and COR stages
        str("FPD") | str("pD") | str("PD") | str("FD") | str("D")) do |acc, stage|
        acc | str(stage)
      end
    end

    rule(:type) do
      (
        Renderer::Russian::TYPE.values.reduce(
          str("DATA") | str("ISP") | str("IWA") | str("R") | str("TTA") |
          str("TS") | str("TR") | str("PAS") | str("Guide") | str("GUIDE")) do |acc, type|
          acc | str(type)
        end
      ).as(:type)
    end

    rule(:tctype) do
      # tc-types
      str("TC") | str("JTC") | str("PC") | str("IT") | str("CAB") | str("CASCO") | str("COPOLCO") |
        str("COUNCIL") | str("CPSG") | str("CS") | str("DEVCO") | str("GA") | str("GAAB") | str("INFCO") |
        str("ISOlutions") | str("ITN") | str("REMCO") | str("TMB") | str("TMBG") | str("WMO") |
        str("DMT") | str("JCG") | str("SGPM") | str("ATMG") | str("CCCC") | str("CCCC-TG") | str("JDMT") |
        str("JSAG") | str("JSCTF-TF") | str("JTCG") | str("JTCG-TF") | str("SAG_Acc") | str("SAG_CRMI") |
        str("SAG_CRMI_CG") | str("SAG_ESG") | str("SAG_ESG_CG") | str("SAG_MRS") | str("SAG SF") | str("SAG SF_CG") |
        str("SMCC") | str("STMG") | str("MENA STAR")
    end

    rule(:sctype) do
      str("SC")
    end

    rule(:wgtype) do
      str("AG") | str("AHG") | str("AhG") | str("WG") | str("JWG") | str("QC") | str("TF") |
        str("PPC") | str("CAG") | str("WG SGDG") | str("WG SR") | str("STAR") | str("STTF") | str("TIG") |
        str("CPAG") | str("CSC") | str("ITSAG") | str("CSC/FIN") | str("CSC/NOM") | str("CSC/OVE") |
        str("CSC/SP") | str("CSC/FIN") | str("JAG")
    end

    rule(:part) do
      (str("-") | str("/")) >> space? >>
        (str("Amd") | str("Cor")).absent? >> (match['[\dA-Z]'] | str("-")).repeat(1).as(:part)
    end

    rule(:organization) do
      Renderer::Russian::PUBLISHER.values.reduce(
        str("IEC") | str("IEEE") | str("CIW") | str("SAE") |
        str("CIE") | str("ASME") | str("ASTM") | str("OECD") | str("ISO") |
        str("IWA") | str("HL7") | str("CEI")) do |acc, publisher|
        acc | str(publisher)
      end
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
        (space | str(".")) >>
        digits.as(:version) >>
        (str(":") >> digits.as(:number)).maybe).as(:amendments)
    end

    rule(:corrigendum) do
      ((str("/") >> stage.as(:stage)).maybe >>
      (str("/") | space).maybe >>
        (str("Cor") | str("COR")) >>
        (space | str(".")) >>
        digits.as(:version) >>
        (str(":") >> digits.as(:number)).maybe).as(:corrigendums)
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
        (str("|") >> (str("IDF") >> space >> digits).as(:joint_document)).maybe >>
        part.maybe >> iteration.maybe >>
        (space? >> str(":") >> year).maybe >>
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
