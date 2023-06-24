module Pubid::Itu
  class Parser < Pubid::Core::Parser

    rule(:part) do
      (dash >> digits.as(:part)).repeat
    end

    rule(:sector_series) do
      ((str("R").as(:sector) >> space >> array_to_str(Identifier.config.series["R"].keys).as(:series)) |
        (str("T").as(:sector) >> space >> array_to_str(Identifier.config.series["T"].keys).as(:series)) | str("D"))
    end

    rule(:identifier) do
      str("ITU-") >> sector_series >> dot >> digits.as(:number) >> part
    end

    rule(:root) { identifier }
  end
end
