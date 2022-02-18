module NistPubid
  module Parsers
    class Default < Parslet::Parser
      rule(:identifier) do
        stage.maybe >> (str(" ") | str(".")) >> report_number >> parts.repeat.as(:parts)
      end

      rule(:parts) do
        (edition | revision | version | volume | part | update | addendum | translation |
           supplement | errata | index | insert | section | appendix)
      end

      rule(:appendix) do
        str("app").as(:appendix)
      end

      rule(:supplement) do
        (str("supp") | str("sup")) >> match('\d').repeat.as(:supplement)
      end

      rule(:errata) do
        str("-").maybe >> str("errata").as(:errata)
      end

      rule(:index) do
        (str("index") | str("indx")).as(:index)
      end

      rule(:insert) do
        (str("insert") | str("ins")).as(:insert)
      end

      rule(:stage) do
        (str("(") >> (STAGES.keys.reduce do |acc, s|
          (acc.is_a?(String) ? str(acc) : acc) | str(s)
        end).as(:stage) >> str(")"))
      end

      rule(:report_number) do
        (match('\d').repeat(1).as(:first_report_number) >>
          (str("-") >> (match('\d').repeat(1) >> match("[aA-Z]").maybe).as(:second_report_number)).maybe)
      end

      rule(:part) do
        str("pt") >> match("\\d").as(:part)
      end

      rule(:revision) do
        str("r") >> (match('\d').repeat(1) >> match("[a-z]").maybe).as(:revision)
      end

      rule(:volume) do
        str("v") >> match("\\d").as(:volume)
      end

      rule(:version) do
        str("ver") >> match("\\d").as(:version)
      end

      rule(:update) do
        (str("/Upd") | str("/upd")) >> match("\\d+").repeat(1).as(:update_number) >> str("-") >> match("\\d+").repeat(1).as(:update_year)
      end

      rule(:translation) do
        (str("(") >> match('\w').repeat(3, 3).as(:translation) >> str(")")) |
          (str(".") >> match('\w').repeat(3, 3).as(:translation))
      end

      rule(:edition) do
        str("e") >> match("\\d").repeat(1).as(:edition)
      end

      rule(:addendum) do
        (str("-add") | str(".add-1")).as(:addendum)
      end

      rule(:series) do
        (SERIES["long"].keys
                       .map { |v| [v, v.gsub(" ", ".")]}
                       .flatten
                       .reduce do |acc, s|
          (acc.is_a?(String) ? str(acc) : acc) | str(s)
        end).as(:series)
      end

      rule(:section) do
        str("sec") >> match('\d').repeat(1).as(:section)
      end

      root(:identifier)
    end
  end
end
