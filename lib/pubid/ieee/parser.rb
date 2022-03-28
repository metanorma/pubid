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
    rule(:dash) { str("-") }
    rule(:dot) { str(".") }
    rule(:words_digits) { match('[\dA-Za-z]').repeat(1) }
    rule(:words) { match("[A-Za-z]").repeat(1) }
    rule(:words?) { words.maybe }
    rule(:year_digits) { (str("19") | str("20")) >> match('\d').repeat(2, 2) }

    rule(:month_digits) do
      match('\d').repeat(2, 2)
    end

    rule(:day_digits) do
      match('\d').repeat(2, 2)
    end

    rule(:year) do
      # -2014, April 2015
      dash >> year_digits.as(:adoption_year) >> publication_date |
        (dot | dash) >> year_digits.as(:year)
    end

    rule(:organization) do
      str("IEEE") | str("AIEE") | str("ANSI") | str("ASA") | str("NCTA") | str("IEC") | str("ISO")
    end

    rule(:number) do
      ((digits | match("[A-Z]")).repeat(1) >> match("[a-z]").maybe).as(:number)
    end

    rule(:type) do
      str("Std") | str("STD") | str("Standard")# | str("Draft Std") | str("Draft")
    end

    rule(:comma_month_year) do
      comma >> words.as(:month) >> space >> year_digits.as(:year)
    end


    rule(:edition) do
      (comma >> year_digits.as(:year) >> str(" Edition")) |
        ((space | dash) >> str("Edition ") >> (digits >> dot >> digits).as(:version) >> (str(" - ") | space) >>
        year_digits.as(:year) >> (dash >>
          month_digits.as(:month)).maybe) |
        #, February 2018 (E)
        (comma_month_year >> str(" (E)")) |
        # First edition 2002-11-01
        space >> str("First").as(:version) >>
        str(" edition ") >>
          year_digits.as(:year) >> dash >>
          month_digits.as(:month) >> (dash >>
          day_digits.as(:day)).maybe

    end

    rule(:draft_status) do
      (str("Active Unapproved") | str("Unapproved") | str("Approved")).as(:draft_status)
    end

    rule(:draft_prefix) do
      str("/") | str("_") | dash
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
        ((dot | str("r")) >> (digits >> words?).as(:revision)).maybe >>
        draft_date.maybe
    end

    rule(:part) do
      ((dot | dash) >> words_digits).as(:part)
    end

    rule(:subpart) do
      (dot | dash) >> match('[\da-z]').repeat(1)
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
        (dash >> match('[\dA-Za-z]').repeat(5, 6)).as(:part) |
        # 581.1978
        year |
        # 61691-6
        part
    end

    rule(:dual_pubids) do
      space >>
        (
          (str("(") >> (identifier_with_organization.as(:alternative) >> str(", ").maybe).repeat(1) >> str(")")) |
          (str("and ") >> identifier.as(:alternative)) |
          # should have an organization when no brackets
          identifier_with_organization.as(:alternative)
        )
    end

    rule(:revision) do
      space >>
        str("(Revision of ") >> identifier.as(:revision_identifier) >>
        str(")")
    end

    rule(:previous_amendments) do
      # IEEE P802.3bp/D3.4, April 2016 (Amendment of IEEE Std 802.3-2015 as amended by IEEE Std 802.3bw-2015,
      # IEEE Std 802.3by-201X, and IEEE Std 802.3bq-201X)
      str(" as amended by ") >>
        (identifier.as(:previous_amendments) >> (str(", ") >> str("and ").maybe).maybe).repeat(1)
    end

    rule(:amendment) do
      space >>
        str("(Amendment ") >> (str("of") | str("to")) >> space >>
        identifier.as(:amendment_identifier) >> previous_amendments.maybe >>
        str(")")
    end

    rule(:number_prefix) do
      ((str("No") | str("no")) >> (str(". ") | dot | space)).maybe
    end

    rule(:redline) do
      str(" - ") >> str("Redline").as(:redline)
    end

    rule(:publication_date) do
      comma_month_year
    end

    rule(:parameters) do
      ((draft_status >> space).maybe >> (str("Draft ").maybe >>
         type.as(:type) >> space).maybe).as(:type_status) >>
         number_prefix >> number >>
        (
          # IEEE P2410-D4, July 2019
          (draft.as(:draft) | part_subpart_year.maybe >> draft.as(:draft).maybe) >>
          publication_date.maybe >>
          edition.as(:edition).maybe >>
          # dual-PubIDs
          dual_pubids.maybe >>
          # Hack: putting revision_identifier inside revision ({revision: {revision_identifier: ...}})
          # to apply transform without including all parameters
          revision.as(:revision).maybe >>
          amendment.as(:amendment).maybe >>
          redline.maybe
        ).as(:parameters)
    end

    rule(:organizations) do
      (organization.as(:publisher) >> (str("/") >> space? >> organization.as(:copublisher)).repeat)
        .as(:organizations)
    end

    rule(:identifier_with_organization) do
      organizations >> space? >> parameters
    end

    rule(:identifier) do
      (organizations >> space).maybe >> parameters
    end

    rule(:root) { identifier }
  end
end
