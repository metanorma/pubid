module Pubid::Itu
  class Parser < Pubid::Core::Parser
    rule(:roman_numerals) do
      array_to_str(%w[I V X L C D M]).repeat(1).as(:roman_numerals)
    end

    rule(:part) do
      (dash >> year_digits.absent? >> digits.as(:part)).repeat
    end

    rule(:type) do
      (dash | space) >> str("REC").as(:type)
    end

    rule(:subseries) do
      dot >> digits.as(:subseries)
    end

    rule(:r_sector_series) do
      (
        # SG - Study groups for "question" type
        ((str("SG") >> digits).as(:series) >> dot) |
          # Recommendation series
          (array_to_str(Identifier.config.series["R"].keys.sort_by(&:length).reverse).as(:series) >> dot) |
          # Regulatory Publications
          (str("RR") | str("RRX") | str("RR5") | str("ROP") | str("HFBS")).as(:regulatory_publication) |
          # "R" for resolution
          (str("R").as(:series) >> dot).maybe)
    end

    rule(:t_sector_series) do
      (
        # Service Publications / Operational Bulletin
        str("OB") | str("Operational Bulletin") |
          # Recommendation series
          array_to_str(Identifier.config.series["T"].keys.sort_by(&:length).reverse)
      ).capture(:series).as(:series) >>
        # "No. " for Operational Bulletin
        (dot | str(" No. ")).maybe
    end

    rule(:series_range) do
      (dash >> dynamic { |s, c| str(c.captures[:series]) } >> dot >> full_number).as(:range)
    end

    rule(:sector_series_number) do
      (
        # ITU-R
        (str("R").as(:sector) >> type.maybe >> (space | dash) >>
          r_sector_series.maybe >> full_number.maybe) |
        # ITU-T
        (str("T").as(:sector) >> type.maybe >> (space | dash) >>
          t_sector_series.maybe >> full_number >>
          (str("/") >> t_sector_series.maybe >> full_number).as(:second_number).maybe >>
          series_range.maybe) |
        # ITU-D
        (str("D") >> space >> full_number)
      )
    end

    rule(:published) do
      ((str(" - ") >> digits.as(:day) >> dot >> roman_numerals.as(:month) >> dot >> year_digits.as(:year)) |
        (dash >> year_digits.as(:year) >> month_digits.as(:month)) |
        (space >> str("(") >> (month_digits.as(:month) >> str("/")).maybe >>
          year_digits.as(:year) >> str(")"))).as(:date)
    end

    rule(:amendment) do
      space >> (str("Amd") | str("Amend")) >> dot.maybe >> space >> digits.as(:number).as(:amendment)
    end

    rule(:implementers_guide) do
      str("Imp").as(:type)
    end

    rule(:full_number) do
      # Parse X.ImpOSI
      ((implementers_guide >> str("OSI").as(:number)) |
        (implementers_guide.maybe >> digits.as(:number).maybe)
      ) >> subseries.maybe >> part
    end

    rule(:supplement) do
      space >> (str("Suppl.") >> space >> digits.as(:number)).as(:supplement)
    end

    rule(:annex) do
      space >> str("Annex") >> space >> (match["A-Z"] >> digits.maybe >> str("+").maybe).as(:number).as(:annex)
    end

    rule(:annex_to) do
      str("Annex to ").as(:annex)
    end

    rule(:corrigendum) do
      (published >> space >> str("Cor.") >> space >>
        digits.as(:number)).as(:corrigendum)
    end

    rule(:addendum) do
      (published >> space >> str("Add.") >> space >> digits.as(:number)).as(:addendum)
    end

    rule(:appendix) do
      (space >> str("App.") >> space >>
        roman_numerals.as(:number)).as(:appendix)
    end

    rule(:language) do
      str("-") >> match["EFASCR"].as(:language)
    end

    rule(:identifier) do
      annex_to.maybe >> str("ITU") >> (dash | space) >> sector_series_number >> supplement.maybe >>
        annex.maybe >> corrigendum.maybe >> addendum.maybe >> appendix.maybe >>
        published.maybe >> amendment.maybe >> str("-I").maybe >> language.maybe
    end

    rule(:root) { identifier }
  end
end
