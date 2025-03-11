require 'forwardable'

module Pubid::Etsi
  module Identifier
    class Base < Pubid::Core::Identifier::Base
      extend Forwardable

      attr_accessor :version, :published

      def self.type
        { key: :etsi }
      end

      def initialize(type:, published:, publisher: "ETSI", version: nil, part: nil, **opts)
        super(**opts.merge(publisher: publisher))
        @published = published
        @version = version
        @part = part
        if type
          unless Identifier.config.type_names.map { |_, v| v[:short] }.include?(type)
            raise Pubid::Core::Errors::WrongTypeError, "Type '#{type}' is not available"
          end
          @type = type
        end
      end

      class << self
        def transform_supplements(type, identifier_params)
          Identifier.create(
            type: type,
            base: transform(
              **identifier_params.dup.tap { |h| h.delete(type) },
            ),
            **identifier_params[type],
          )
        end

        # Use Identifier#create to resolve identifier's type class
        def transform(params)
          identifier_params = params.map do |k, v|
            get_transformer_class.new.apply(k => v)
          end.inject({}, :merge)

          %i(amendment corrigendum).each do |type|
            return transform_supplements(type, identifier_params) if identifier_params[type]
          end
          Identifier.create(**identifier_params)
        end

        def get_parser_class
          Parser
        end

        def get_renderer_class
          Renderer::Base
        end
      end
    end
  end
end
