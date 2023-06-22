require "pubid-iso"

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
      (dot | dash) >> year_digits.as(:year) >> str("(E)").maybe
    end

    rule(:organization) do
      str("IEEE") | str("AIEE") | str("ANSI") | str("ASA") | str("NCTA") |
        str("IEC") | str("ISO") | str("ASTM") | str("NACE") | str("NSF")
    end

    rule(:number) do
      str("D").absent? >> ((digits | match("[A-Z]")).repeat(1) >> match("[a-z]").maybe).as(:number)
    end

    rule(:type) do
      str("Std") | str("STD") | str("Standard")
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
        (comma_month_year >> str("(E)")) |
        # (comma_month_year >> space? >> str("(E)")) |
        # comma_month_year |
        # First edition 2002-11-01
        space >> str("First").as(:version) >>
        str(" edition ") >>
          year_digits.as(:year) >> dash >>
          month_digits.as(:month) >> (dash >>
          day_digits.as(:day)).maybe

    end

    rule(:draft_status) do
      (str("Active Unapproved") | str("Unapproved") | str("Approved"))
    end

    rule(:draft_prefix) do
      space? >> str("/") | str("_") | dash | space
    end

    rule(:draft_date) do
      ((space? >> comma | space) >> words.as(:month)).maybe >>
        (
          ((space >> digits.as(:day)).maybe >> comma >> year_digits.as(:year)) |
            (comma_space >> match('\d').repeat(2, 4).as(:year))
        )
    end

    rule(:draft_version) do
      # for D1D2
      (str("D") >> digits.as(:version)).repeat(2) |
      # for DD3, D3Q
      # don't parse "DIS" as draft
      (str("D") >> str("IS").absent? >> words_digits.as(:version)).repeat(1, 1)
    end

    rule(:draft) do
      # /D14, April 2020
      # /D7 November, 2019
      (draft_prefix >> draft_version >>
        ((dot | str("r")) >> (digits >> words?).as(:revision)).maybe >>
        draft_date.maybe).as(:draft)
    end

    rule(:part) do
      ((dot | dash) >> iso_stage_iteration.absent? >> words_digits).as(:part)
    end

    rule(:subpart) do
      (dot | dash) >> ((str("REV") | str("Rev")).maybe >> match('[\da-z]').repeat(1) | (str("REV") | str("Rev")))
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
      space? >>
        (
          (str("(") >> (iso_identifier >> iso_parameters).as(:alternative) >> str(")") |
            str("(") >> (parameters(organizations >> space?).as(:alternative) >> str(", ").maybe).repeat(1) >> str(")")) |
          ((str("and ") | str("/ ") | space) >> identifier_no_params.as(:alternative)) |
          (str("/") >> identifier_with_organization.as(:alternative)) |
          # should have an organization when no brackets
          identifier_with_organization.as(:alternative)
        )
    end

    rule(:dual_pubid_without_parameters) do
      space? >>
        (
          (str("(") >> (iso_identifier >> iso_parameters).as(:alternative) >> str(")") |
            str("(") >> (identifier_no_params.as(:alternative) >> str(", ").maybe).repeat(1) >> str(")"))# |
          #identifier_no_params.as(:alternative)
        )
    end

    rule(:revision) do
      (str("Revision ") >> (str("of") | str("to")) >> space >>
        (identifier_without_dual_pubids.as(:identifier) >> str(" and ").maybe).repeat(1)
      ).as(:revision)
    end

    rule(:adoption) do
      str("Adoption of ") >> identifier_without_dual_pubids.as(:adoption)
    end

    rule(:previous_amendments) do
      # IEEE P802.3bp/D3.4, April 2016 (Amendment of IEEE Std 802.3-2015 as amended by IEEE Std 802.3bw-2015,
      # IEEE Std 802.3by-201X, and IEEE Std 802.3bq-201X)
      str(",").maybe >> str(" as amended by ") >>
        (identifier_inside_brackets.as(:identifier) >> (str(", ") >> str("and ").maybe).maybe).repeat(1)
    end

    # match everything before "," or ")" or " as"
    rule(:identifier_inside_brackets) do
      ((str(" as") | str(")") | str(",")).absent? >> any).repeat(1) >>
        (str(", ") >> year_digits >> str(" Edition")).maybe
    end

    rule(:amendment) do
      (str("Amendment ") >> (str("of") | str("to")) >> space >>
        identifier_inside_brackets.as(:identifier) >> previous_amendments.maybe).as(:amendment)
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

    rule(:supersedes) do
      (str("Supersedes ") >> (identifier_without_dual_pubids.as(:identifier) >>
        (str(" and ") | str(" ")).maybe).repeat(1)).as(:supersedes)
    end

    rule(:incorporates) do
      (
        match("[Ii]") >> (str("ncorporates ") | str("ncorporating ")) >>
          (identifier_without_dual_pubids.as(:identifier) >> str(", and ").maybe).repeat(1)
      ).as(:incorporates)
    end

    rule(:supplement) do
      (str("Supplement") >> str("s").maybe >> str(" to ") >> identifier_without_dual_pubids.as(:identifier)).as(:supplement)
    end

    rule(:includes) do
      (str("Includes ") >>
        ((str("Supplement ") >> identifier_without_dual_pubids.as(:identifier)).as(:supplement) | identifier_without_dual_pubids.as(:identifier))).as(:includes)
    end

    rule(:additional_parameters) do
      (space? >> str("(") >> (
        (reaffirmed | revision | amendment | supersedes |
          corrigendum_comment| incorporates | supplement | includes | adoption) >>
          ((str("/") | str(",")) >> space?).maybe).repeat >> str(")").maybe
      ).repeat >> redline.maybe
    end

    # Hack to exclude dual_pubids parsing for revisions and supersedes
    # otherwise extra identifiers parsed as dual PubIDs to the main identifier
    def parameters(atom, without_dual_pubids: false, skip_parameters: false)
      atom >>
        ((draft_status.as(:draft_status) >> space).maybe >> (str("Draft ").maybe >>
          type.as(:type) >> space.maybe).maybe).as(:type_status) >>
        number_prefix >> number >>
        (
          # IEEE P2410-D4, July 2019
          (draft |
            part_subpart_year.maybe >> corrigendum.maybe >> draft.maybe >> iso_amendment.maybe
          ) >>
            # iso_stage_part_iteration.maybe >>
            # ((str("-") | str("/") | str("_")) >> (str("D") >> digits).absent? >>
            #   (iso_parser.typed_stage.as(:stage) | iso_parser.stage.as(:stage))) >> digits.as(:iteration).maybe >>
            if skip_parameters
              str("")
            else
              publication_date.maybe
            end >>
            if skip_parameters
              str("")
            else
              edition.as(:edition).maybe
            end >>
            # dual-PubIDs
            ((without_dual_pubids && str("")) || dual_pubids.maybe) >>
            if skip_parameters
              str("")
            else
              additional_parameters.maybe
            end
        ).as(:parameters)
    end

    rule(:reaffirmed) do
      (
        (str("Reaffirmed ") >> year_digits.as(:year) |
          str("Reaffirmation of ") >> identifier.as(:identifier).as(:reaffirmation_of))
      ).as(:reaffirmed)
    end

    rule(:corrigendum_prefix) do
      (str("_") | str("/") | str("-")) >> str("Cor") >> (str("-") | dot.maybe >> space?)
    end

    rule(:corrigendum) do
      # IEEE 1672-2006/Cor 1-2008
      (
        corrigendum_prefix >> digits.as(:version) >> ((dash | str(":")) >> year_digits.as(:year)).maybe
      ).as(:corrigendum)
    end

    rule(:corrigendum_comment) do
      ((str("Corrigendum to ") | str("Corrigenda ") >> (str("to ") | str("of "))) >>
        identifier.as(:identifier)).as(:corrigendum_comment)
    end

    rule(:iso_amendment_prefix) do
      str("/") >> str("Amd")
    end

    rule(:iso_amendment) do
      # IEEE 1672-2006/Cor 1-2008
      (iso_amendment_prefix >> digits.as(:version) >> (dash >> year_digits.as(:year)).maybe).as(:iso_amendment)
    end

    rule(:organizations) do
      (organization.as(:publisher) >> (str("/") >> space? >> organization.as(:copublisher)).repeat)
        .as(:organizations)
    end

    rule(:identifier_with_organization) do
      parameters(organizations >> space?)
    end

    rule(:identifier_with_org_no_params) do
      iso_identifier | parameters(organizations >> space?, skip_parameters: true)
    end

    rule(:identifier_no_params) do
      parameters((organizations >> space).maybe, skip_parameters: true, without_dual_pubids: true)
    end

    rule(:iso_part) do
      (str("-") | str("/")) >> str(" ").maybe >>
        # (str("-") >> iso_parser.stage).absent? >>
        ((match('\d') | str("A")) >>
          ((str("-") >> iso_parser.typed_stage).absent? >>
          (match['\d[A-Z]'] | str("-"))).repeat).as(:part)
    end

    rule(:iso_part_stage_iteration) do
      iso_part >> (str("-") | str("/") | str("_")) >> iso_stage_iteration >> iso_parser.iteration.maybe
    end

    rule(:iso_stage_part_iteration) do
      # don't consume draft from IEEE format
      (str("-") | str("/") | str("_") | space) >> (str("D") >> digits).absent? >>
        iso_stage_iteration >> iso_part.maybe >> iso_parser.iteration.maybe
    end

    # add rule when don't have stage
    #
    rule(:iso_part_iteration) do
      iso_part >> iso_parser.iteration.maybe
    end

    rule(:iso_stage_iteration) do
      (iso_parser.typed_stage | iso_parser.stage).as(:stage) >> digits.as(:iteration).maybe
    end

    rule(:iso_part_stage_iteration_matcher) do
      # consumes "/"
      iso_part_stage_iteration |
      iso_stage_part_iteration |
      iso_part_iteration# |
      # iso_stage_iteration
    end

    rule(:iso_identifier) do
      # Pubid::Iso::Parser.new.identifier.as(:iso_identifier)
        # Withdrawn e.g: WD/ISO 10360-5:2000
        # for French and Russian PubIDs starting with Guide type
      ((iso_parser.guide_prefix.as(:type) >> str(" ")).maybe >>
      (iso_parser.typed_stage.as(:stage) >> str(" ")).maybe >>
        iso_parser.originator >> ((str(" ") | str("/")) >>
      # for ISO/FDIS
      (iso_parser.type | iso_parser.typed_stage.as(:stage))).maybe >>
      # draft std
      # (space >> (draft_status >> space).maybe >> (str("Draft ").maybe >> type >> space.maybe)).maybe >>
      # for ISO/IEC WD TS 25025
      str(" ").maybe >> ((iso_parser.typed_stage.as(:stage) | iso_parser.stage.as(:stage) | iso_parser.type) >> str(" ")).maybe >>
        (str("P").maybe >> iso_parser.digits).as(:number) >> iso_parser.iteration.maybe >>
      # for identifiers like ISO 5537/IDF 26
      (str("|") >> (str("IDF") >> str(" ") >> digits).as(:joint_document)).maybe >>
        iso_part_stage_iteration_matcher.maybe >>
      (str(" ").maybe >> str(":") >> iso_parser.year).maybe >>
      # stage before amendment
      (
      # stage before corrigendum
      iso_parser.supplement.maybe) >>
        iso_parser.language.maybe).as(:iso_identifier)
    end

    rule(:iso_parameters) do
      iso_amendment.maybe >> (dual_pubid_without_parameters.maybe >>
        (publication_date >> space? >> str("(E)").maybe).maybe >>
        edition.as(:edition).maybe >> draft.maybe >> additional_parameters).as(:parameters)
    end

    rule(:identifier_before_edition) do
      ((str(" Edition")).absent? >> any).repeat(1)
    end

    rule(:identifier) do
      iso_or_ieee_identifier
      # (identifier_before_edition.as(:iso_identifier).as(:iso_identifier) >> iso_parameters) |
    end

    rule(:ieee_without_prefix) do
      (str("IEEE").as(:publisher).as(:organizations) >> space) >>
        digits.as(:number) >> str(".").absent? >> year.as(:parameters)
    end

    rule(:iso_or_ieee_identifier) do
      ieee_without_prefix |
        parameters((organizations >> space).maybe) |
        (iso_identifier >> iso_parameters) |
        # (iso identifier) >> space >> (ieee identifier) ?
        iso_identifier >> space >> parameters((organizations >> space).maybe) | iso_identifier

      # iso_identifier >> iso_parameters
    end

    rule(:parameters_with_optional_organizations) do
      parameters((organizations >> space).maybe)
    end

    rule(:identifier_without_dual_pubids) do
      (iso_identifier >> iso_parameters) |
      parameters((organizations >> space).maybe, without_dual_pubids: true)
    end

    rule(:identifier_without_parameters) do
      parameters((organizations >> space).maybe, skip_parameters: true)
    end

    rule(:root) { identifier }

    def iso_parser
      Pubid::Iso::Parser.new
    end
  end
end
