module Pubid::Ieee
  class Parser < Parslet::Parser
    rule(:digits) do
      match('\d').repeat(1)
    end

    rule(:space) { str(" ") }
    rule(:space?) { space.maybe }
    rule(:comma) { str(", ") }
    rule(:comma?) { comma.maybe }
    rule(:comma_space) { comma | space }
    rule(:words_digits) { match('[\dA-Za-z]').repeat(1) }
    rule(:words) { match("[A-Za-z]").repeat(1) }
    rule(:words?) { words.maybe }
    rule(:year_digits) { match('\d').repeat(4, 4) }

    rule(:year) do
      (str(".") | str("-")) >> year_digits.as(:year)
    end

    rule(:organization) do
      str("IEEE") | str("AIEE") | str("ANSI") | str("ASA") | str("NCTA") | str("IEC") | str("ISO")
    end

    rule(:number) do
      ((digits | match("[A-Z]")).repeat(1) >> match("[a-z]").maybe).as(:number)
    end

    rule(:part) do
      (str(".") | str("-")) >> match('[\dA-Za-z]').repeat(1).as(:part)
    end

    rule(:subpart) do
      (str(".") | str("-")) >> match('[\da-z]').repeat(1)
    end

    rule(:type) do
      str("Std") | str("STD") | str("Standard")# | str("Draft Std") | str("Draft")
    end

    rule(:edition) do
      (comma >> match('\d').repeat(4, 4).as(:year) >> str(" Edition")) |
        ((space | str("-")) >> str("Edition ") >> (digits >> str(".") >> digits).as(:version) >> (str(" - ") | str(" ")) >>
        match('\d').repeat(4, 4).as(:year) >> (str("-") >>
        match('\d').repeat(2, 2).as(:month)).maybe) |
        #, February 2018 (E)
        (comma >> match('[a-zA-Z]').repeat(1).as(:month) >> str(" ") >> match('\d').repeat(4, 4).as(:year) >>
          str(" (E)")) |
        # First edition 2002-11-01
        space >> str("First").as(:version) >>
        str(" edition ") >>
          match('\d').repeat(4, 4).as(:year) >> str("-") >>
          match('\d').repeat(2, 2).as(:month) >> (str("-") >>
          match('\d').repeat(2, 2).as(:day)).maybe

    end

    rule(:draft_status) do
      space >> (str("Active Unapproved") | str("Unapproved") | str("Approved")).as(:draft_status)
    end

    rule(:draft_prefix) do
      str("/") | str("_")
    end

    rule(:draft_date) do
      (space? >> comma | space) >> words.as(:month) >>
        (
          ((space >> digits.as(:day)).maybe >> comma >> year_digits.as(:year)) |
            (comma_space >> match('\d').repeat(2, 4).as(:year))
        )
    end

    rule(:draft_version) do
      # for D1D2
      (str("D") >> digits.as(:version)).repeat(2) |
      # for DD3, D3Q
      (str("D") >> words_digits.as(:version)).repeat(1, 1)
    end

    rule(:draft) do
      # /D14, April 2020
      # /D7 November, 2019
      space? >> draft_prefix >> draft_version >>
        ((str(".") | str("r")) >> (digits >> words?).as(:revision)).maybe >>
        draft_date.maybe
    end

    rule(:part_subpart_year) do
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
        (part >> subpart.as(:subpart)) |
        # IEC 62525-Edition 1.0 - 2007
        edition.as(:edition) |
        # IEEE P11073-10101
        # IEEE P11073-10420/D4D5
        # IEEE Unapproved Draft Std P11073-20601a/D13, Jan 2010
        # XXX: hack to avoid being partially parsed by year
        (str("-") >> match('[\dA-Za-z]').repeat(5, 6).as(:part)) |
        # 581.1978
        year |
        # 61691-6
        part

    end

    rule(:dual_pubids) do
      str(" ") >>
        ((str("(") >> (identifier.as(:alternative) >> str(", ").maybe).repeat(1) >>
          str(")")) | (str("and ") >> identifier.as(:alternative)) |
          identifier.as(:alternative))
    end

    rule(:number_prefix) do
      ((str("No") | str("no")) >> (str(".") | str(" "))).maybe >> str(" ").maybe
    end

    rule(:identifier) do
      (organization.as(:publisher) >> ((str("/ ") | str("/")) >> organization.as(:copublisher)).repeat)
        .as(:organizations) >>
        (draft_status.maybe >> (str(" ") >> str("Draft ").maybe >>
          type.as(:type) >> str(" ")).maybe).as(:type_status) >>
        str(" ").maybe >> number_prefix >> number >> (part_subpart_year.maybe >> draft.as(:draft).maybe >>
        edition.as(:edition).maybe >>
        # dual-PubIDs
        dual_pubids.maybe).as(:parameters)
    end

    rule(:root) { identifier }
  end
end
