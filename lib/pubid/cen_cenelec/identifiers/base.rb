# frozen_string_literal: true

module Pubid
  module CenCenelec
    module Identifiers
      # Base CEN identifier (one of two roots; see Pubid::CenCenelec::Identifier).
      # Format: {PUBLISHER} NUMBER[-PART]:YEAR
      class Base < Pubid::CenCenelec::Identifier
        # Generate URN for this identifier
        #
        # @return [String] URN representation

        attribute :publisher, :string, collection: true # EN, CEN, CLC, etc.
        attribute :type, :string # TR, TS, Guide
        # `number` is inherited as a :string from Pubid::CenCenelec::Identifier;
        # a same-type redeclaration here is the determinism landmine in
        # miniature, and it moves the generated accessor onto this class.
        attribute :parts, :string, collection: true
        attribute :year, :integer
        attribute :stage, :string # prEN, FprEN
        attribute :supplements, :string, collection: true # Amendments and corrigenda
        attribute :adopted_identifier, Base, polymorphic: true # Nested identifier object (ISO, IEC, etc.)
        attribute :edition, :string # Edition number

        def ==(other)
          return false unless other.is_a?(Base)

          publisher == other.publisher && number == other.number &&
            parts == other.parts && year == other.year
        end
      end
    end
  end
end
