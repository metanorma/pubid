require 'forwardable'

module Pubid::Ccsds
  module Identifier
    class Base < Pubid::Core::Identifier::Base
      extend Forwardable

      attr_accessor :series, :retired, :book_color

      def self.type
        { key: :ccsds, title: "The Consultative Committee for Space Data Systems" }
      end

      def initialize(publisher: "CCSDS", book_color: nil, part: nil,
                     series: nil, retired: nil, **opts)
        super(**opts.merge(publisher: publisher))
        @book_color = book_color
        @part = part || 0
        @series = series
        @retired = retired
      end

      class << self
        def transform_supplements(type, identifier_params)
          Identifier.create(
            type: type,
            base: transform(
              **identifier_params.dup.tap { |h| h.delete(type) }),
            **identifier_params[type],
            )
        end

        # Use Identifier#create to resolve identifier's type class
        def transform(params)
          identifier_params = params.map do |k, v|
            get_transformer_class.new.apply(k => v)
          end.inject({}, :merge)

          %i(corrigendum).each do |type|
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
