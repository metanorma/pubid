require 'forwardable'

module Pubid::Ccsds
  module Identifier
    class Base < Pubid::Core::Identifier::Base
      extend Forwardable

      def self.type
        { key: :ccsds, title: "The Consultative Committee for Space Data Systems" }
      end

      def initialize(publisher: "CCSDS", part: nil, **opts)
        super(**opts.merge(publisher: publisher))
        @part = part || 0
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
