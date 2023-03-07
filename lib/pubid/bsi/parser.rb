module Pubid::Bsi
  class Parser < Pubid::Core::Parser
    TYPES = %w[PAS PD].freeze

    rule(:type) do
      array_to_str(TYPES).as(:type)
    end

    rule(:part) do
      str("-") >> digits.as(:part)
    end

    rule(:identifier) do
      (str("BS") | type) >> space >> digits.as(:number) >> part.maybe >> (space? >> str(":") >> year).maybe
    end

    rule(:root) { identifier }
  end
end
