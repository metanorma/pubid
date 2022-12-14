module Pubid::Iso
  module Identifier
    class InternationalWorkshopAgreement < Base
      def_delegators 'Pubid::Iso::Identifier::InternationalWorkshopAgreement', :type

      TYPED_STAGES = {
        dis: {
          abbr: "DIWA",
          name: "Draft International Workshop Agreement",
          harmonized_stages: %w[40.00 40.20 40.60 40.92 40.93],
        },
        fdis: {
          abbr: "FDIWA",
          name: "Final Draft International Workshop Agreement",
          harmonized_stages: %w[50.00 50.20 50.60 50.92 50.98 50.99],
        },
      }.freeze

      def self.type
        :iwa
      end

      def self.get_renderer_class
        Renderer::InternationalWorkshopAgreement
      end
    end
  end
end
