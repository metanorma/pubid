require_relative "../renderer/guide"

module Pubid::Cen
  module Identifier
    class CenWorkshopAgreement < Base
      def_delegators 'Pubid::Cen::Identifier::CenWorkshopAgreement', :type

      def self.get_renderer_class
        Renderer::CenWorkshopAgreement
      end

      def self.type
        { key: :cwa, title: "Cen Workshop Agreement", short: "CWA" }
      end
    end
  end
end
