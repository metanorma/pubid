# from https://github.com/relaton/relaton-iso/issues/47#issuecomment-512251416
# ISO {num}-{docpart}:{year} - docpart and year are optioal. docpart is [\w-]+
#   ISO/{stage} {num}-{docpart}:{year} or ISO/{subprefix} {stage} {num}:{year} - stages are WD, CD, DIS, FDIS, AWI
# ISO/{subprefix} {stage} {num}-{docpart}:{year} - subpefixes are IEC, IEEE, IEC/IEEE, TR, R. Any other?
# ISO {num}:{year}/{correction} {cornum}:{coryear} - corrections are Amd, DAmd, Cor. coryear is optional
# ISO {num}:{year}/{corstage} {correction} {cornum}:{coryear} - corstages are CD, NP, AWI, PRF, WD, DIS. Any others?

module PubidIso
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
      (str("NP") | str("WD") | str("CD") | str("DIS") | str("FDIS") | str("PRF") |
        str("IS")).as(:stage)
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
        str("TS") | str("TR") | str("PAS") | str("Guide")).as(:type)
    end

    rule(:year) do
      match('\d').repeat(4, 4)
    end

    rule(:part) do
      (str("-") | str("/")) >> (match['[\dA-Z]'] | str("-")).repeat(1).as(:part)
    end

    rule(:originator) do
      (str("ISO") | str("IWA") | str("IEC")).as(:publisher) >> (str(" ").maybe >>
        str("/") >> copublisher).maybe
    end

    rule(:copublisher) do
      (str("IEC/IEEE") | str("IEC") | str("IEEE") | str("CIW") | str("SAE") |
        str("CIE") | str("ASME") | str("ASTM")).as(:copublisher)
    end

    rule(:edition) do
      str(" ") >> ((str("ED") | str("Ed ") | str("Ed.")) >>
        digits.as(:edition) | str("Ed").as(:edition))
    end

    rule(:iteration) do
      str(".") >> digits.as(:iteration)
    end

    rule(:identifier) do
      str("Fpr").as(:stage).maybe >> originator >> ((str(" ") | str("/")) >>
        # for ISO/FDIS
        (type | stage)).maybe >>
        # for ISO/IEC WD TS 25025
        str(" ") >> ((stage | type) >> str(" ")).maybe >>
        digits.as(:number) >> iteration.maybe >> part.maybe >>
        (str(" ").maybe >> str(":") >> year).maybe >> edition.maybe
    end

    rule(:root) { identifier }
  end
end
