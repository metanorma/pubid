module Pubid::Bsi
  module Identifier
    class Collection < Base
      def_delegators 'Pubid::Bsi::Identifier::Collection', :type

      attr_accessor :identifiers

      def initialize(identifiers:, **args)
        @identifiers = identifiers
        super(publisher: nil, number: nil, **args)
      end

      def self.type
        { key: :collection, title: "Collection" }
      end

      def to_s
        Renderer::Collection.new(to_h(deep: false)).render
      end
    end
  end
end
