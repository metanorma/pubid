require 'forwardable'

module Pubid::Plateau
  module Identifier
    class Base < Pubid::Core::Identifier::Base
      extend Forwardable

      attr_accessor :annex, :type

      def self.type
        { key: :plateau }
      end

      def initialize(publisher: "PLATEAU", annex: nil, edition: nil, **opts)
        @annex = annex if annex
        @edition = edition if edition
        super(**opts.merge(publisher: publisher))
      end

      class << self
        def transform(params)
          identifier_params = params.map do |k, v|
            get_transformer_class.new.apply(k => v).to_a.first
          end.to_h

          Identifier.create(**identifier_params)
        end

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
