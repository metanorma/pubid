require 'forwardable'

module Pubid::Itu
  module Identifier
    class Base < Pubid::Core::Identifier::Base
      attr_accessor :series, :sector, :date, :amendment, :subseries,
                    :second_number, :annex, :range

      extend Forwardable

      def self.type
        { key: :itu, title: "International Communication Union" }
      end

      # @param month [Integer] document's month
      # @param edition [String] document's edition version, e.g. "3.0", "1.0"
      def initialize(publisher: "ITU", series: nil, sector: nil, part: nil,
                     date: nil, amendment: nil, subseries: nil, number: nil,
                     second_number: nil, annex: nil, range: nil, **opts)

        super(**opts.merge(publisher: publisher, number: number))
        @series = series
        @sector = sector
        @part = part if part
        @date = date
        @amendment = amendment
        @subseries = subseries
        @second_number = second_number
        @annex = annex
        @range = range
      end

      def to_s(**opts)
        self.class.get_renderer_class.new(to_h(deep: false)).render(**opts)
      end

      class << self
        # returns true when type matching current class type
        def has_type?(type)
          return type == self.type[:key] if type.is_a?(Symbol)

          if self.type.key?(:short)
            self.type[:short].is_a?(Array) ? self.type[:short].include?(type) : self.type[:short] == type
          else
            type.to_s.downcase.to_sym == self.type[:key]
          end
        end

        def transform_supplements(type, identifier_params)
          if identifier_params[type].is_a?(Hash)
            Identifier.create(
              type: type,
              base: transform(
                **identifier_params.dup.tap { |h| h.delete(type) }),
              **identifier_params[type],
            )
          else
            Identifier.create(
              type: type,
              base: transform(**identifier_params.dup.tap { |h| h.delete(type) })
            )
          end
        end

        # Use Identifier#create to resolve identifier's type class
        def transform(params)
          identifier_params = params.map do |k, v|
            get_transformer_class.new.apply(k => v)
          end.inject({}, :merge)

          %i(supplement amendment corrigendum annex addendum appendix).each do |type|
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

        def get_transformer_class
          Transformer
        end
      end
    end
  end
end
