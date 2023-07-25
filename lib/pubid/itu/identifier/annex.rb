module Pubid::Itu
  module Identifier
    class Annex < Base
      def_delegators 'Pubid::Itu::Identifier::Annex', :type

      def initialize(base: nil, **opts)
        super(**opts)
        @base = base
      end

      def to_s
        self.class.get_renderer_class.new(
          @base.get_params.merge({ annex: self }),
        ).render
      end

      def self.type
        { key: :annex, title: "Annex" }
      end
    end
  end
end
