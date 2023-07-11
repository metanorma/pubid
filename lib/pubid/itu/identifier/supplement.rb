module Pubid::Itu
  module Identifier
    class Supplement < Base
      def_delegators 'Pubid::Itu::Identifier::Supplement', :type

      attr_accessor :base

      def initialize(base: nil, **opts)
        super(**opts)
        @base = base
      end

      def to_s
        self.class.get_renderer_class.new(
          @base.get_params.merge({ supplement: self }),
        ).render
      end

      def self.type
        { key: :sup, title: "Supplement" }
      end
    end
  end
end
