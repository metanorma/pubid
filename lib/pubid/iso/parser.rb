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
    rule(:digits) do
      match('\d').repeat(1)
    end

    rule(:stage) do
      # other stages
      str("NP") | str("WD") | str("CD") | str("DIS") | str("FDIS") | str("PRF") |
      str("IS") | str("AWI") | str("PWI") |
      # AMD and COR stages
      str("FPD") | str("pD") | str("PD") | str("FD") | str("D")
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
      (str("DATA") | str("ISP") | str("IWA") | str("R") | str("TTA") |
        str("TS") | str("TR") | str("PAS") | str("Guide") | str("GUIDE") |
        str("PDTR") | str("PDTS")).as(:type)
    end

    rule(:year) do
      match('\d').repeat(4, 4).as(:year)
    end

    rule(:part) do
      (str("-") | str("/")) >> str(" ").maybe >>
        (match['[\dA-Z]'] | str("-")).repeat(1).as(:part)
    end

    rule(:originator) do
      organization.as(:publisher) >>
        (str(" ").maybe >> str("/") >> organization.as(:copublisher)).repeat
    end

    rule(:organization) do
      str("IEC") | str("IEEE") | str("CIW") | str("SAE") |
        str("CIE") | str("ASME") | str("ASTM") | str("OECD") | str("ISO") |
        str("IWA") | str("HL7")
    end

    rule(:edition) do
      str(" ") >> ((str("ED") | str("Ed ") | str("Ed.")) >>
        digits.as(:edition) | str("Ed").as(:edition))
    end

    rule(:iteration) do
      str(".") >> digits.as(:iteration)
    end

    rule(:amendment) do
      (str("/") >> stage.as(:amendment_stage)).maybe >>
      (str("/") | str(" ")).maybe >>
        (str("Amd") | str("AMD") | str("AM")).as(:amendment) >>
        (str(" ") | str(".")) >>
        digits.as(:amendment_version) >>
        (str(":") >> digits.as(:amendment_number)).maybe
    end

    rule(:corrigendum) do
      (str("/") >> stage.as(:corrigendum_stage)).maybe >>
      (str("/") | str(" ")).maybe >>
        (str("Cor") | str("COR")).as(:corrigendum) >>
        (str(" ") | str(".")) >>
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

    rule(:identifier) do
      str("Fpr").as(:stage).maybe >>
        # Withdrawn e.g: WD/ISO 10360-5:2000
        str("WD/").maybe >>
        originator >> ((str(" ") | str("/")) >>
        # for ISO/FDIS
        (type | stage.as(:stage))).maybe >>
        # for ISO/IEC WD TS 25025
        str(" ").maybe >> ((stage.as(:stage) | type) >> str(" ")).maybe >>
        digits.as(:number) >> part.maybe >> iteration.maybe >>
        (str(" ").maybe >> str(":") >> year).maybe >>
        # stage before amendment
        (
        # stage before corrigendum
        ((amendment >> corrigendum.maybe) | corrigendum).maybe) >>
        edition.maybe >>
        language.maybe
    end

    rule(:root) { identifier }
  end
end
