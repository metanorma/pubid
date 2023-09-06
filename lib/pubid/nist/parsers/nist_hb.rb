require_relative "nbs_hb"

module Pubid::Nist
  module Parsers
    class NistHb < NbsHb
      rule(:number_suffix) { match("[a-zA-Z]") }
    end
  end
end
