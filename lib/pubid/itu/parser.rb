module Pubid::Itu
  class Parser < Pubid::Core::Parser

    rule(:part) do
      (dash >> digits.as(:part)).repeat
    end

    rule(:sector_series) do
      ((str("R").as(:sector) >> space >>
        # "R" for resolution
        (((str("SG") >> digits) | array_to_str(Identifier.config.series["R"].keys.sort_by(&:length).reverse) | str("R")).as(:series) >> dot).maybe) |
        (str("T").as(:sector) >> space >> (array_to_str(Identifier.config.series["T"].keys.sort_by(&:length).reverse).as(:series) >> dot).maybe) | str("D"))
    end

    rule(:identifier) do
      str("ITU-") >> sector_series >> digits.as(:number) >> part
    end

    rule(:root) { identifier }
  end
end
