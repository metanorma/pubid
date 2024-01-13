require_relative "../renderer/international_workshop_agreement"

module Pubid::Iso
  module Identifier
    class InternationalWorkshopAgreement < Base
      def_delegators 'Pubid::Iso::Identifier::InternationalWorkshopAgreement', :type

      TYPED_STAGES = {
        diwa: {
          abbr: "DIWA",
          name: "Draft International Workshop Agreement",
          harmonized_stages: %w[40.00 40.20 40.60 40.92 40.93 40.98 40.99],
        },
      }.freeze

      def self.type
        { key: :iwa, title: "International Workshop Agreement", short: "IWA" }
      end

      def self.get_renderer_class
        Renderer::InternationalWorkshopAgreement
      end
    end
  end
end
