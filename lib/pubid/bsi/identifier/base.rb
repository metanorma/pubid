require 'forwardable'

module Pubid::Bsi
  module Identifier
    class Base < Pubid::Core::Identifier
      extend Forwardable

      def initialize(publisher: "BS", **opts)
        super(**opts.merge(publisher: publisher))
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
      end
    end
  end
end
