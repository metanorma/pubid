module Pubid::Bsi
  module Identifier
    class ExpertCommentary < Base
      attr_accessor :base

      def_delegators 'Pubid::Bsi::Identifier::ExpertCommentary', :type

      def initialize(base: nil, **opts)
        super(**opts)
        @base = base
      end

      def self.type
        { key: :ec, title: "Expert Commentary", short: "ExComm" }
      end

      def self.get_renderer_class
        Renderer::ExpertCommentary
      end
    end
  end
end
