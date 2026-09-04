# frozen_string_literal: true

module Pubid
  module Jcgm
    class Identifier < ::Pubid::Identifier
      # `number`/`part`/`subpart` are declared here rather than inherited as a
      # Components::Code: JCGM stores a bare string in `number` and uses neither
      # of the other two. Declaring on this class is safe because its body lives
      # in this one file and is never reopened, so every subclass body opens
      # after it has run (lutaml deep-dups the parent attribute table at
      # class-definition time).
      attribute :number, :string
      attribute :part, :string
      attribute :subpart, :string

      def self.parse(string)
        Pubid::Jcgm.parse(string)
      end
    end
  end
end
