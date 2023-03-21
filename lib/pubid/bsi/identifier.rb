module Pubid::Bsi
  module Identifier
    class << self
      include Pubid::Core::Identifier

      # @see Pubid::Identifier::Base.parse
      def parse(*args)
        Pubid::Iec::Identifier.parse(*args)
      rescue Pubid::Core::Errors::ParseError
        begin
          Base.parse(*args)
        rescue Pubid::Core::Errors::ParseError
          Pubid::Iso::Identifier.parse(*args)
        end
      end
    end
  end
end
