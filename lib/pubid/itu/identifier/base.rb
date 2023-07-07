require 'forwardable'

module Pubid::Itu
  module Identifier
    class Base < Pubid::Core::Identifier::Base
      attr_accessor :series, :sector, :date, :amendment, :subseries

      extend Forwardable

      def self.type
        { key: :itu, title: "International Communication Union" }
      end

      # @param month [Integer] document's month
      # @param edition [String] document's edition version, e.g. "3.0", "1.0"
      def initialize(publisher: "ITU", series: nil, sector: nil, part: nil,
                     date: nil, amendment: nil, subseries: nil, number: nil, **opts)
        super(**opts.merge(publisher: publisher, number: number))
        @series = series
        @sector = sector
        @part = part if part
        @date = date
        @amendment = amendment
        @subseries = subseries
      end

      def to_s(**opts)
        self.class.get_renderer_class.new(get_params).render(**opts)
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

        # Use Identifier#create to resolve identifier's type class
        def transform(params)
          identifier_params = params.map do |k, v|
            get_transformer_class.new.apply(k => v)
          end.inject({}, :merge)

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
