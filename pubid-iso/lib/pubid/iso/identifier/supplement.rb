require_relative "../renderer/supplement"
require_relative "../renderer/urn-supplement"

module Pubid::Iso
  module Identifier
    class Supplement < Base
      def_delegators 'Pubid::Iso::Identifier::Supplement', :type

      TYPED_STAGES = {
        dsuppl: {
          abbr: "DSuppl",
          name: "Draft Supplement",
          harmonized_stages: %w[40.00 40.20 40.60 40.92 40.93 40.98 40.99],
        },
        fdsuppl: {
          abbr: "FDIS Suppl",
          name: "Final Draft Supplement",
          harmonized_stages: %w[50.00 50.20 50.60 50.92 50.98 50.99],
        },
      }.freeze

      def initialize(publisher: nil, **opts)
        super(publisher: publisher, **opts)
      end

      def base_has_edition?
        @base.base.nil? && !@base.edition.nil? || (!@base.base.nil? && !@base.base.edition.nil?)
      end

      def self.type
        { key: :sup, title: "Supplement", values: %w[Supplement Suppl SUP], short: "SUP" }
      end

      def self.get_renderer_class
        Renderer::Supplement
      end

      def urn
        Renderer::UrnSupplement.new(to_h(deep: false)).render
      end
    end
  end
end
