# frozen_string_literal: true

module Pubid
  module Ieee
    module Identifiers
      module Nesc
        # Draft NESC identifier
        #
        # Represents draft versions of the National Electrical Safety Code
        # that are under development or review.
        #
        # @example
        #   nesc = Pubid::Ieee.parse("Draft NESC, June 2011")
        #   nesc.to_s
        #   # => "Draft National Electrical Safety Code, June 2011"
        #
        # NOTE: the spelled-out "Draft National Electrical Safety Code, …" form
        # is claimed by the generic IEEE grammar before it reaches the NESC
        # sub-parser, so it does not currently build this class. Pre-existing
        # dispatcher gap, pinned in spec/pubid/ieee/ire_nesc_roundtrip_spec.rb.
        class Draft < Base
          include Pubid::Ieee::Identifiers::CodeNumber

          def self.polymorphic_name
            "pubid:ieee:nesc-draft"
          end

          # Render draft identifier
          #
          # @param trademark [Boolean] append the IEEE trademark symbol (™/®)
          # @return [String] Draft format with optional month and year
          def to_s(trademark: false)
            parts = ["Draft National Electrical Safety Code"]
            parts << ", #{month} #{year}" if month && year
            result = parts.join
            result += trademark_symbol if trademark
            result
          end
        end
      end
    end
  end
end
