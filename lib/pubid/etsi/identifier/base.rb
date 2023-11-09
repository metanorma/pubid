require 'forwardable'

module Pubid::Etsi
  module Identifier
    class Base < Pubid::Core::Identifier::Base
      extend Forwardable

      attr_accessor :version, :published

      # def self.type
      #   { key: :ccsds, title: "The Consultative Committee for Space Data Systems" }
      # end

      def initialize(publisher: "ETSI", published: , version: nil, part: nil, **opts)
        super(**opts.merge(publisher: publisher))
        @published = published
        @version = version
        @part = part
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
