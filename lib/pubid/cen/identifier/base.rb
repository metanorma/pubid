require 'forwardable'

module Pubid::Cen
  module Identifier
    class Base < Pubid::Core::Identifier::Base
      extend Forwardable

      def self.type
        { key: :en, title: "European Norm" }
      end

      # @param month [Integer] document's month
      # @param edition [String] document's edition version, e.g. "3.0", "1.0"
      def initialize(publisher: "EN", part: nil, stage: nil, **opts)
        super(**opts.merge(publisher: publisher))
        @part = part if part
        @stage = Identifier.parse_stage(stage) if stage
      end

      class << self
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
