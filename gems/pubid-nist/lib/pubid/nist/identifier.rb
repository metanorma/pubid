module Pubid::Nist
  module Identifier
    class << self
      include Pubid::Core::Identifier

      def parse(*args)
        Base.parse(*args)
      end
    end
  end
end
