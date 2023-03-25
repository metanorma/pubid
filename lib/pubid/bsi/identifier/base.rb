require 'forwardable'

module Pubid::Bsi
  module Identifier
    class Base < Pubid::Core::Identifier::Base
      attr_accessor :month, :supplement
      extend Forwardable

      # @param month [Integer] document's month
      # @param edition [String] document's edition version, e.g. "3.0", "1.0"
      def initialize(publisher: "BS", month: nil, edition: nil, supplement: nil, **opts)
        super(**opts.merge(publisher: publisher))
        @month = month if month
        @edition = edition if edition
        @supplement = supplement
      end

      class << self
        # Use Identifier#create to resolve identifier's type class
        def transform(params)
          identifier_params = params.map do |k, v|
            get_transformer_class.new.apply(k => v)
          end.inject({}, :merge)

          Identifier.create(**identifier_params)
        end

        def get_parser_class
          Parser
        end

        def get_renderer_class
          Renderer::Base
        end

        def get_transformer_class
          Transformer
        end
      end
    end
  end
end
