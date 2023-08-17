require 'forwardable'

module Pubid::Ccsds
  module Identifier
    class Base < Pubid::Core::Identifier::Base
      extend Forwardable

      attr_accessor :series

      def self.type
        { key: :ccsds, title: "The Consultative Committee for Space Data Systems" }
      end

      def initialize(publisher: "CCSDS", part: nil, series: nil, **opts)
        super(**opts.merge(publisher: publisher))
        @part = part || 0
        @series = series
      end

      class << self
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
