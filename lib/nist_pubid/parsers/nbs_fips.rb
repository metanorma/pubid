module NistPubid
  module Parsers
    class NbsFips < Default
      rule(:edition) do
        str("-") >> ((match('\w').repeat(3, 3).as(:edition_month) >>
          match("\\d").repeat(4, 4).as(:edition_year)) | match("\\d").repeat(4, 4).as(:edition_year) |
          (match('\w').repeat(3, 3).as(:edition_month) >> match("\\d").repeat(2, 2).as(:edition_day) >>
            str("/") >> match("\\d").repeat(4, 4).as(:edition_year)))
      end
    end
  end
end
