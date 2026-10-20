# frozen_string_literal: true

module Pubid
  module UrnParser
    # Deprecated. The URN error moved to {Pubid::Errors::UrnParseError}, so
    # that every pubid failure lives in one namespace under the marker module
    # {Pubid::Errors::Error}. This alias keeps the nine `raise` sites in the
    # flavor URN parsers, and any consumer rescuing the old name, working
    # unchanged.
    module Errors
      ParseError = ::Pubid::Errors::UrnParseError
    end
  end
end
