module Pubid::Iso
  module Identifier
    class << self
      # Resolve identifier's class and create new identifier
      # @see Pubid::Identifier::Base.initialize for available options
      def create(**opts)
        resolve_identifier(
          opts[:type],
          opts[:stage],
          opts.reject { |k, _v| [:type, :stage].include?(k) })
      end

      # @param typed_stage_or_stage [String] typed stage or stage
      # @return identifier's class
      def resolve_identifier(type, typed_stage_or_stage, parameters = {})
        return Identifier::InternationalStandard.new(**parameters) if type.nil? && typed_stage_or_stage.nil?

        Base.descendants.each do |identifier_type|
          if type
            return identifier_type.new(stage: typed_stage_or_stage, **parameters) if identifier_type.has_type?(type)

            next
          elsif identifier_type.has_typed_stage?(typed_stage_or_stage)
            return identifier_type.new(stage: typed_stage_or_stage, **parameters)
          end
        end

        # When stage is not typed stage and type is not defined
        if type.nil? && Stage.has_stage?(typed_stage_or_stage)
          return Identifier::InternationalStandard.new(stage: typed_stage_or_stage, **parameters)
        end

        raise Errors::TypeStageParseError, "cannot parse typed stage or stage '#{typed_stage_or_stage}'" if type.nil?

        raise Errors::ParseTypeError, "cannot parse type #{type}"
      end

      # @see Pubid::Identifier::Base.parse
      def parse(*args)
        Base.parse(*args)
      end

      # Parse identifier from title
      def parse_from_title(title)
        title.split.reverse.inject(title) do |acc, part|
          return Base.parse(acc)
        rescue Pubid::Core::Errors::ParseError
          # delete parts from the title until it's parseable
          acc.reverse.sub(part.reverse, "").reverse.strip
        end

        raise Errors::ParseError, "cannot parse #{title}"
      end
    end
  end
end
