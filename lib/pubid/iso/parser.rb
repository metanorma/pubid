# from https://github.com/relaton/relaton-iso/issues/47#issuecomment-512251416
# ISO {num}-{docpart}:{year} - docpart and year are optional. docpart is [\w-]+
#   ISO/{stage} {num}-{docpart}:{year} or ISO/{subprefix} {stage} {num}:{year} - stages are WD, CD, DIS, FDIS, AWI
# ISO/{subprefix} {stage} {num}-{docpart}:{year} - subpefixes are IEC, IEEE, IEC/IEEE, TR, R. Any other?
# ISO {num}:{year}/{correction} {cornum}:{coryear} - corrections are Amd, DAmd, Cor. coryear is optional
# ISO {num}:{year}/{corstage} {correction} {cornum}:{coryear} - corstages are CD, NP, AWI, PRF, WD, DIS. Any others?

module Pubid::Iso
  # ISO/IEC FDIS 7816-6
  # ISO/IEC/IEEE 15289:2019
  #
  # Stage 10: NP (non-public)
  # Stage 20: WD (non-public)
  # Stage 30: CD
  # Stage 40: DIS
  # Stage 50: FDIS
  # Stage 50.60: PRF ("proof") (non-public)
  # Stage 60: IS
  class Parser < Parslet::Parser
    rule(:space) { str(" ") }
    rule(:space?) { space.maybe }

    rule(:digits) do
      match('\d').repeat(1)
    end

    rule(:stage) do
      Russian::STAGE.values.reduce(
        # other stages
        str("NP") | str("WD") | str("CD") | str("DIS") | str("FDIS") | str("PRF") |
        str("IS") | str("AWI") | str("PWI") |
        # AMD and COR stages
        str("FPD") | str("pD") | str("PD") | str("FD") | str("D")) do |acc, stage|
        acc | str(stage)
      end
    end

    # TYPES = {
    #   "TS" => "technical-specification",
    #   "TR" => "technical-report",
    #   "PAS" => "publicly-available-specification",
    #   "Guide" => "guide",
    # }.freeze
    # DATA|GUIDE|ISP|IWA|PAS|R|TR|TS|TTA
    #       # type          = "data" / "guide" / "isp" / "iwa" /
    #       #   "pas" / "r" / "tr" / "ts" / "tta"
    rule(:type) do
      (
        Russian::TYPE.values.reduce(
          str("DATA") | str("ISP") | str("IWA") | str("R") | str("TTA") |
          str("TS") | str("TR") | str("PAS") | str("Guide") | str("GUIDE")) do |acc, type|
          acc | str(type)
        end
      ).as(:type)
    end

    rule(:tctype) do
      # tc-types
      str("TC") | str("JTC") | str("PC") | str("IT")
    end

    rule(:sctype) do
      str("SC")
    end

    rule(:wgtype) do
      str("AG") | str("AHG") | str("AhG") | str("WG") | str("JWG") | str("QC") | str("TF") |
        str("PPC") | str("CAG")
    end

    rule(:year) do
      match('\d').repeat(4, 4).as(:year)
    end

    rule(:part) do
      (str("-") | str("/")) >> space? >>
        (str("Amd") | str("Cor")).absent? >> (match['[\dA-Z]'] | str("-")).repeat(1).as(:part)
    end

    rule(:originator) do
      organization.as(:publisher) >>
        (space? >> str("/") >> organization.as(:copublisher)).repeat
    end

    rule(:organization) do
      Russian::PUBLISHER.values.reduce(
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
      (str("/") >> stage.as(:amendment_stage)).maybe >>
      (str("/") | space).maybe >>
        (str("Amd") | str("AMD") | str("AM")).as(:amendment) >>
        (space | str(".")) >>
        digits.as(:amendment_version) >>
        (str(":") >> digits.as(:amendment_number)).maybe
    end

    rule(:corrigendum) do
      (str("/") >> stage.as(:corrigendum_stage)).maybe >>
      (str("/") | space).maybe >>
        (str("Cor") | str("COR")).as(:corrigendum) >>
        (space | str(".")) >>
        digits.as(:corrigendum_version) >>
        (str(":") >> digits.as(:corrigendum_number)).maybe
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

    rule(:identifier) do
      str("Fpr").as(:stage).maybe >>
        # Withdrawn e.g: WD/ISO 10360-5:2000
        str("WD/").maybe >>
        # for French and Russian PubIDs starting with Guide type
        (guide_prefix.as(:type) >> space).maybe >>
        (stage.as(:stage) >> space).maybe >>

        originator >> (space | str("/")) >>
        # Parse technical committee documents
        (
          (
            tctype.as(:tctype) >> space >> digits.as(:tcnumber) >>
            (str("/") >> (
              ((sctype.as(:sctype) >> space >> digits.as(:scnumber) >> str("/")).maybe >>
                wgtype.as(:wgtype) >> space >> digits.as(:wgnumber)) |
              (sctype.as(:sctype) >> (space | str("/") >> wgtype.as(:wgtype) >> space) >> digits.as(:scnumber))
            )).maybe >>
            str(" N") >> space? >> digits.as(:number)
          ) |

        # for ISO/FDIS
        ((type | stage.as(:stage)).maybe >>
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
        language.maybe))
    end

    rule(:root) { identifier }
  end
end
