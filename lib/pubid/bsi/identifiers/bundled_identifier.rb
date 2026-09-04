# frozen_string_literal: true

require "lutaml/model"

module Pubid
  module Bsi
    module Identifiers
      # BundledIdentifier represents multiple standards published together
      # Examples:
      #   BS SP 10 & 11:1949
      #   BS 2SP 68 to BS 2SP 71:1973
      #   BS SP 13; 14; 15 and 16:1949
      #   BS 4048:Parts 1 and 2:1966
      class BundledIdentifier < SingleIdentifier
        attribute :identifiers, ::Pubid::Identifier, collection: true, 
                                                     polymorphic: true
        attribute :separators, :string, collection: true # Separators between identifiers
        attribute :common_year, Bsi::Components::Date # Year applied to all if present
        attribute :bundle_type, :string # "Parts", "Sections", or nil for regular bundles

        def <=>(other)
          return nil unless other.is_a?(BundledIdentifier)

          # Compare first identifier
          identifiers.first <=> other.identifiers.first
        end

        # A bundle carries no number of its own — each member holds one — so
        # `root.number`, the key relaton-index sorts and bsearches on, was "".
        # Walk to the first member, the shape ConsolidatedIdentifier already
        # uses. Members of one bundle are consecutive numbers of a single
        # series, so the bundle files under the first, and `<=>` above orders
        # bundles by that same member.
        def root
          identifiers&.first ? identifiers.first.root : self
        end
      end
    end
  end
end
