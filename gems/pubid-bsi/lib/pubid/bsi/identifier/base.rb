require 'forwardable'

module Pubid::Bsi
  module Identifier
    class Base < Pubid::Core::Identifier::Base
      attr_accessor :month, :supplement, :adopted, :tracked_changes, :translation, :pdf

      extend Forwardable

      # @param month [Integer] document's month
      # @param edition [String] document's edition version, e.g. "3.0", "1.0"
      def initialize(publisher: "BS", month: nil, edition: nil,
                     supplement: nil, number: nil, adopted: nil,
                     expert_commentary: false, tracked_changes: false,
                     translation: nil, pdf: false, **opts)

        super(**opts.merge(publisher: publisher, number: number))
        @month = month if month
        @edition = edition if edition
        @supplement = supplement
        @adopted = adopted
        @tracked_changes = tracked_changes
        @translation = translation
        @pdf = pdf
      end

      class << self
        def transform_hash(params)
          params.map do |k, v|
            get_transformer_class.new.apply(k => v.is_a?(Hash) ? transform_hash(v) : v)
          end.inject({}, :merge)
        end
        
        # Use Identifier#create to resolve identifier's type class
        def transform(params)
          identifier_params = transform_hash(params)

          if identifier_params[:national_annex]
            return transform_national_annex(
              identifier_params[:national_annex],
              identifier_params.dup.tap { |h| h.delete(:national_annex) })
          end

          return transform_expert_commentary(identifier_params) if identifier_params[:expert_commentary]

          return transform_collection(identifier_params) if identifier_params[:second_number]

          Identifier.create(**identifier_params)
        end

        def transform_collection(params)
          first_identifier_params =
            params.reject { |k, _| %i[second_number year supplement].include?(k) }
          second_identifier_params = first_identifier_params.dup
          second_identifier_params[:number] = params[:second_number]
          Collection.new(identifiers: [Identifier.create(**first_identifier_params),
                                       Identifier.create(**second_identifier_params)],
                         **params.slice(:supplement, :year))
        end

        def transform_expert_commentary(base_params)
          Identifier.create(type: :ec,
                            base: Identifier.create(**base_params))
        end

        def transform_national_annex(params, base_params)
          Identifier.create(type: params[:type],
                            supplement: params[:supplement],
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
