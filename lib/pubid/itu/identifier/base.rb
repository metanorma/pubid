require 'forwardable'

module Pubid::Itu
  module Identifier
    class Base < Pubid::Core::Identifier::Base
      attr_accessor :series, :sector

      extend Forwardable

      def self.type
        { key: :itu, title: "International Communication Union" }
      end

      # @param month [Integer] document's month
      # @param edition [String] document's edition version, e.g. "3.0", "1.0"
      def initialize(publisher: "ITU", series: nil, sector:, part: nil, **opts)
        super(**opts.merge(publisher: publisher))
        @series = series
        @sector = sector
        @part = part if part
      end

      def to_s
        self.class.get_renderer_class.new(get_params).render
      end

      class << self
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
      end
    end
  end
end
