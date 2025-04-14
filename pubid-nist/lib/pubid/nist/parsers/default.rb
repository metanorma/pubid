module Pubid::Nist
  module Parsers
    class Default < Pubid::Core::Parser
      rule(:identifier) do
        old_stage.maybe >> (str(" ") | str(".")) >> report_number >>
          parts.repeat >> draft.maybe >> stage.maybe >> translation.maybe
      end

      rule(:month_letters) { match('[A-Za-z]').repeat(3, 3) }
      rule(:number_suffix) { match("[aA-Z]") }

      rule(:parts) do
        (edition | revision | version | volume | part | update | addendum |
           supplement | errata | index | insert | section | appendix)
      end

      rule(:appendix) do
        str("app").as(:appendix)
      end

      rule(:supplement) do
        (str("supp") | str("sup")) >> match('[A-Z\d]').repeat.as(:supplement)
      end

      rule(:errata) do
        str("-").maybe >> (str("errata") | str("err")).as(:errata)
      end

      rule(:index) do
        (str("index") | str("indx")).as(:index)
      end

      rule(:insert) do
        (str("insert") | str("ins")).as(:insert)
      end

      rule(:old_stage) do
        (str("(") >> (array_to_str(STAGES["id"].keys.map(&:upcase)).as(:id) >>
          array_to_str(STAGES["type"].keys.map(&:upcase)).as(:type)).as(:stage) >> str(")"))
      end

      rule(:stage) do
        ((space | dot) >> (array_to_str(STAGES["id"].keys + STAGES["id"].keys.map(&:upcase)).as(:id) >>
          array_to_str(STAGES["type"].keys + STAGES["type"].keys.map(&:upcase)).as(:type)).as(:stage))
      end

      rule(:draft) do
        space >> str("(Draft)").as(:draft)
      end

      rule(:digits_with_suffix) do
        digits >> # do not match with 428P1
          (number_suffix >> match('\d').absent?).maybe
      end

      rule(:first_report_number) do
        digits_with_suffix.as(:first_report_number)
      end

      rule(:second_report_number) do
        digits_with_suffix.as(:second_report_number)
      end

      rule(:report_number) do
        first_report_number >> (str("-") >> second_report_number).maybe
      end

      rule(:part_prefixes) { str("pt") | str("p") }

      rule(:part) do
        part_prefixes >> (digits >> (str("-") >> digits).maybe).as(:part)
      end

      rule(:revision) do
        str("r") >> ((digits >> match("[a-z]").maybe).maybe).as(:revision)
      end

      rule(:volume) do
        str("v") >> digits.as(:volume)
      end

      rule(:version) do
        str("ver") >> digits.as(:version)
      end

      rule(:update) do
        (str("/Upd") | str("/upd") | str("-upd")) >> (digits.as(:number) >> (str("-") >> digits.as(:year)).maybe).as(:update)
      end

      rule(:translation) do
        (str("(") >> match('\w').repeat(3, 3).as(:translation) >> str(")")) |
          ((str(".") | space) >> match('\w').repeat(3, 3).as(:translation))
      end

      rule(:edition_prefixes) { str("e") }

      rule(:edition) do
        edition_prefixes >> digits.as(:edition)
      end

      rule(:addendum) do
        (str("-add") | str(".add") | str(" Add.")) >>
          (str(" ") | str("-")).maybe >> (digits | str("")).as(:number).as(:addendum)
      end

      rule(:section) do
        str("sec") >> digits.as(:section)
      end

      root(:identifier)
    end
  end
end
