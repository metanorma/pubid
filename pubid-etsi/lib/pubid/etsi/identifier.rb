module Pubid::Etsi
  module Identifier
    class << self
      include Pubid::Core::Identifier

      # @see Pubid::Identifier::Base.parse
      def parse(*args)
        Base.parse(*args)
      end

      def resolve_identifier(parameters = {})
        return @config.default_type.new(**parameters) if parameters[:type].nil?

        @config.types.each do |identifier_type|
          if identifier_type.type_match?(parameters)
            return identifier_type.new(**parameters.reject { |k, _| k == :type })
          end
        end

        @config.default_type.new(**parameters)
      end

    end
  end
end
