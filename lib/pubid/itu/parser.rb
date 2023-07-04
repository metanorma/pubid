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

    rule(:sector_series) do
      (
        # ITU-R
        (str("R").as(:sector) >> type.maybe >> (space | dash) >>
          ((
            # SG - Study groups for "question" type
            (str("SG") >> digits) |
            # Recommendation series
            array_to_str(Identifier.config.series["R"].keys.sort_by(&:length).reverse) |
            # "R" for resolution
            str("R")).as(:series) >> dot).maybe) |
        # ITU-T
        (str("T").as(:sector) >> type.maybe >> (space | dash) >>
          ((
            # Service Publications / Operational Bulletin
            str("OB") | str("Operational Bulletin") |
            # Recommendation series
            array_to_str(Identifier.config.series["T"].keys.sort_by(&:length).reverse)
          ).as(:series) >> (dot | str(" No. "))).maybe) |
        # ITU-D
        str("D")
      )
    end

    rule(:published) do
      ((str(" - ") >> digits.as(:day) >> dot >> roman_numerals.as(:month) >> dot >> year_digits.as(:year)) |
        (dash >> year_digits.as(:year) >> month_digits.as(:month)) |
        (space >> str("(") >> (month_digits.as(:month) >> str("/")).maybe >>
          year_digits.as(:year) >> str(")"))).as(:date)
    end

    rule(:identifier) do
      str("ITU") >> (dash | space) >> sector_series >> digits.as(:number) >> part >> published.maybe >> str("-I").maybe
    end

    rule(:root) { identifier }
  end
end
