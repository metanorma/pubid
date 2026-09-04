# frozen_string_literal: true

module Pubid
  module CenCenelec
    # Common base class for all CEN/CENELEC identifiers. CEN/CENELEC has a split
    # hierarchy — some concrete types descend from Identifiers::Base, others from
    # SingleIdentifier — so this class is the shared parent of BOTH, making every
    # CEN/CENELEC identifier `is_a?(Pubid::CenCenelec::Identifier)` natively (and
    # giving them the shared polymorphic `from_hash`). No facade needed.
    class Identifier < ::Pubid::Identifier
      # `number`/`part`/`subpart` are declared here rather than inherited as a
      # Components::Code: CEN/CENELEC stores a bare string in every one of them.
      # This class is the shared parent of BOTH branches, so one declaration
      # here replaces the three that used to disagree (Identifiers::Base said
      # :string, SingleIdentifier inherited Code, SupplementIdentifier declared
      # Code again). Declaring here is safe because this body lives in one file
      # and is never reopened, so every subclass body opens after it has run
      # (lutaml deep-dups the parent attribute table at class-definition time).
      attribute :number, :string
      attribute :part, :string
      attribute :subpart, :string

      def self.parse(identifier)
        if identifier.length > Pubid::MAX_INPUT_LENGTH
          raise ArgumentError, Pubid::INPUT_TOO_LONG_MESSAGE
        end

        parsed = Parser.parse(identifier)
        Builder.new.build(parsed)
      rescue Parslet::ParseFailed => e
        raise "Failed to parse CEN identifier '#{identifier}': #{e.message}"
      end
    end
  end
end
