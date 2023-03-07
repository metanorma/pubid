module Pubid::Bsi
  module Identifier
    class << self
      # Resolve identifier's class and create new identifier
      # @see Pubid::Identifier::Base.initialize for available options
      def create(**opts)
        resolve_identifier(
          opts[:type],
          opts.reject { |k, _v| [:type].include?(k) },
        )
      end

      # @see Pubid::Identifier::Base.parse
      def parse(*args)
        Base.parse(*args)
      end

      def resolve_identifier(type, parameters = {})
        return Identifier::BritishStandard.new(**parameters) if type.nil?

        Base.descendants.each do |identifier_type|
          if type
            return identifier_type.new(**parameters) if identifier_type.has_type?(type)

            next
          end
        end

        raise Errors::ParseTypeError, "cannot parse type #{type}"
      end

    end
  end
end
