# frozen_string_literal: true

module Pubid
  module Ansi
    # Base ANSI identifier class
    class Identifier < ::Pubid::Identifier
      # `number`/`part`/`subpart` are declared here rather than inherited as a
      # Components::Code: ANSI stores a bare string in every one of them.
      # Declaring on this class is safe because its body lives in this one file
      # and is never reopened, so every subclass body opens after it has run
      # (lutaml deep-dups the parent attribute table at class-definition time).
      attribute :number, :string
      attribute :part, :string
      attribute :subpart, :string

      def self.parse(string)
        parsed = Pubid::Ansi::Parser.new.parse(string)
        Pubid::Ansi::Builder.new.build(parsed)
      end
    end
  end
end
