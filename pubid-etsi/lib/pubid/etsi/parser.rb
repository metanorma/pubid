module Pubid::Etsi
  class Parser < Pubid::Core::Parser
    TYPE_NAMES = Identifier.config.type_names.map { |_, v| v[:short] }
    rule(:edition) do
      dash >> (digits >> (dot >> digits).maybe).as(:edition)
    end

    rule(:part) do
      (dash.ignore >> (digits | match("[A-Z]").repeat(3, 3))).as(:part).repeat(1)
    end

    rule(:type) do
      array_to_str(TYPE_NAMES).as(:type)
    end

    rule(:version) do
      str("V") >> match("[0-9\.]").repeat(1).as(:version)
    end

    rule(:published_date) do
      str("(") >> (year_digits >> dash >> month_digits).as(:published) >> str(")")
    end

    rule(:edition) do
      str("ed.") >> digits.as(:edition)
    end

    rule(:amendment) do
      str("/A") >> digits.as(:number).as(:amendment)
    end

    rule(:corrigendum) do
      str("/C") >> digits.as(:number).as(:corrigendum)
    end

    rule(:number) do
      (
        # for identifiers like ETSI GTS GSM 02.01 V5.5.0
        (str("GSM ").maybe.ignore >> match('[\d]').repeat(2, 2) >> dot >>
          match('[\d]').repeat(2, 2)) |
          (match('[A-Za-z\d]').repeat(3, 3) >>
          (dash >> match("[A-Z]").repeat(3, 3)).maybe >>
          (space >> match('\d').repeat(3, 3)).maybe)
      ).as(:number)
    end

    # ETSI ETR 299-1 ed.1 (1996-09)
    # ETSI ETR 298 ed.1 (1996-09)
    #
    rule(:identifier) do
      str("ETSI") >> space >> type >> space >>
        number >> part.maybe >> amendment.maybe >> corrigendum.maybe >> space >>
        (version | edition) >> space >> published_date
    end

    rule(:root) { identifier }
  end
end
