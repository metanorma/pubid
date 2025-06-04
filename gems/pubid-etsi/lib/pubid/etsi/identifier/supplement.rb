module Pubid::Etsi
  module Identifier
    class Supplement < Base
      attr_accessor :base

      def initialize(base:, number:)
        @base = base
        @number = number
      end

      def to_h(**args)
        @base.to_h(**args).merge(self.type[:key] => super)
      end
    end
  end
end
