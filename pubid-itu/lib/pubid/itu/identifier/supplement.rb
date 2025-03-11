module Pubid::Itu
  module Identifier
    class Supplement < Base
      def_delegators 'Pubid::Itu::Identifier::Supplement', :type

      attr_accessor :base

      def initialize(base: nil, **opts)
        super(**opts)
        @base = base
      end

      def to_h(deep: false)
        # XXX: hack to render supplements using Base renderer, because we need to
        # place date published after amendment, e.g. `ITU-T G.780/Y.1351 Amd 1 (2004)`
        @base.to_h(deep: deep).merge(self.type[:key] => super)
      end

      def self.type
        { key: :supplement, title: "Supplement" }
      end
    end
  end
end
