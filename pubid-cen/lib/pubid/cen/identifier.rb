module Pubid::Cen
  module Identifier
    class << self
      include Pubid::Core::Identifier

      # @see Pubid::Identifier::Base.parse
      def parse(*args)
        Base.parse(*args)
      end

      # def resolve_identifier(parameters = {})
      #   return @config.default_type.new(**parameters) if parameters[:type].nil?
      #
      #   @config.types.each do |identifier_type|
      #     return identifier_type.new(**parameters) if identifier_type.type_match?(parameters)
      #   end
      #
      #   raise Errors::ParseTypeError, "cannot parse type #{parameters[:type]}"
      # end
    end
  end
end
