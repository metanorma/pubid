# frozen_string_literal: true

module Pubid
  module W3c
    # Emits `urn:w3c:<type-down>:<slug>[:<date>]`, e.g.
    #   "W3C WD-charmod-19991129" -> "urn:w3c:wd:charmod:19991129"
    #   "W3C 2dcontext"           -> "urn:w3c:2dcontext"
    class UrnGenerator < Pubid::UrnGenerator::Base
      def generate
        parts = ["urn", "w3c"]
        parts << identifier.type_prefix.downcase if identifier.type_prefix
        parts << identifier.number.to_s
        parts << identifier.date.to_s if identifier.date
        parts.join(":")
      end
    end
  end
end
