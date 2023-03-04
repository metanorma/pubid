module Pubid::Bsi
  module Identifier
    class << self
      # Resolve identifier's class and create new identifier
      # @see Pubid::Identifier::Base.initialize for available options
      def create(**opts)
        Base.new(**opts)
      end

      # @see Pubid::Identifier::Base.parse
      def parse(*args)
        Base.parse(*args)
      end
    end
  end
end
