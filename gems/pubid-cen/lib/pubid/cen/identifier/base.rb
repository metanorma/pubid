require 'forwardable'

module Pubid::Cen
  module Identifier
    class Base < Pubid::Core::Identifier::Base
      extend Forwardable
      attr_accessor :supplements, :adopted

      def self.type
        { key: :en, title: "European Norm" }
      end

      # @param month [Integer] document's month
      # @param edition [String] document's edition version, e.g. "3.0", "1.0"
      def initialize(number: nil, publisher: "EN", part: nil, stage: nil,
                     incorporated_supplements: nil, adopted: nil, **opts)
        super(**opts.merge(publisher: publisher, number: number))
        @part = part if part
        @stage = Identifier.parse_stage(stage) if stage
        @supplements = incorporated_supplements
        @adopted = adopted
      end

      class << self
        def transform(params)
          identifier_params = params.map do |k, v|
            get_transformer_class.new.apply(k => v)
          end.inject({}, :merge)

          if identifier_params[:supplement]
            return transform_supplement(
              identifier_params[:supplement],
              identifier_params.dup.tap { |h| h.delete(:supplement) }
            )
          end

          Identifier.create(**identifier_params)
        end

        def transform_supplement(supplement_params, base_params)
          Identifier.create(number: supplement_params[:number],
                            year: supplement_params[:year],
                            type: supplement_params[:type],
                            base: Identifier.create(**base_params))
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
