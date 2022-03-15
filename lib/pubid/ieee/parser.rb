module Pubid::Ieee
  class Parser < Parslet::Parser
    rule(:digits) do
      match('\d').repeat(1)
    end

    rule(:year) do
      (str(".") | str("-")) >> match('\d').repeat(4, 4).as(:year)
    end

    rule(:organization) do
      str("IEEE") | str("AIEE") | str("ANSI")
    end

    rule(:number) do
      (digits | match("[A-Z]")).repeat(1).as(:number)
    end

    rule(:part) do
      (str(".") | str("-")) >> match('[\dA-Z]').repeat(1).as(:part)
    end

    rule(:subpart) do
      (str(".") | str("-")) >> match('\d').repeat(1)
    end

    rule(:type) do
      str("Std") | str("STD") | str("Standard") | str("Draft Std") | str("Draft")
    end

    rule(:identifier) do
      organization.as(:publisher) >> str(" ") >> (type.as(:type) >> str(" ")).maybe >> (
        (str("No") | str("no")) >> (str(".") | str(" "))
      ).maybe >> str(" ").maybe >>
      number >>
        # patterns:
        (
          # 802.15.22.3-2020
          # 1073.1.1.1-2004
          (part >> subpart.repeat(2, 2).as(:subpart) >> year) |
          # C57.12.00-1993
          (part >> subpart.as(:subpart) >> year) |
          # N42.44-2008
          # 1244-5.2000
          # 11073-40102-2020
          # C37.0781-1972
          (part >> year) |
          # C57.19.101
          part >> subpart |
          # 581.1978
          year |
          # 61691-6
          part
        ).maybe
    end

    rule(:root) { identifier }
  end
end
