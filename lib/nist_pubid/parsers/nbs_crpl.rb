module NistPubid
  module Parsers
    class NbsCrpl < Default
      # NBS CRPL 1-2_3-1A
      # SUPPLEMENT_REGEXP = /(?<=_)\d+-\d+([A-Z]+)/.freeze
      # _3-1
      # PART_REGEXP = /_(\d+-\d+)/.freeze
      rule(:report_number) do
        (match('\d').repeat(1) >> str("-m").maybe >>
          (str("-") >> (match('\d').repeat(1))).maybe).as(:first_report_number)
      end

      rule(:part) do
        str("_") >> (match('\d').repeat(1) >> str("-") >> match('\d').repeat(1)).as(:part)
      end

      rule(:supplement) do
        str("A").as(:supplement)
      end
    end
  end
end
