module Pubid::Bsi
  module Identifier
    class Base < Pubid::Core::Identifier
      def initialize(publisher: "BS", **opts)
        super(**opts.merge(publisher: publisher))
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
