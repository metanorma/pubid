module Pubid::Iso
  module Identifier
    class Supplement < Base
      TYPED_STAGES = {}.freeze

      def base_has_edition?
        @base.base.nil? && !@base.edition.nil? || (!@base.base.nil? && !@base.base.edition.nil?)
      end

      def self.type
        :sup
      end

      def self.get_renderer_class
        Renderer::Supplement
      end

      def urn
        Renderer::UrnSupplement.new(get_params).render
      end
    end
  end
end
