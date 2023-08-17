module Pubid::Ccsds
  module Identifier
    class << self
      include Pubid::Core::Identifier

      # @see Pubid::Identifier::Base.parse
      def parse(*args)
        Base.parse(*args)
      end

      def resolve_identifier(parameters = {})
        # don't use type resolving, always return base type
        @config.default_type.new(**parameters)
      end
    end
  end
end
