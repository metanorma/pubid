require 'forwardable'

module Pubid::Bsi
  module Identifier
    class Base < Pubid::Core::Identifier::Base
      attr_accessor :month, :supplement, :adopted, :expert_commentary, :tracked_changes

      extend Forwardable

      # @param month [Integer] document's month
      # @param edition [String] document's edition version, e.g. "3.0", "1.0"
      def initialize(publisher: "BS", month: nil, edition: nil,
                     supplement: nil, number: nil, adopted: nil,
                     expert_commentary: false, tracked_changes: false, **opts)
        
        super(**opts.merge(publisher: publisher, number: number))
        @month = month if month
        @edition = edition if edition
        @supplement = supplement
        @adopted = adopted
        @expert_commentary = expert_commentary
        @tracked_changes = tracked_changes
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

          return Identifier.create(**identifier_params) unless identifier_params[:national_annex]

          transform_national_annex(identifier_params[:national_annex],
                                   identifier_params.dup.tap { |h| h.delete(:national_annex) })
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
