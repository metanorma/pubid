require_relative "../renderer/international_standardized_profile"

module Pubid::Iso
  module Identifier
    class InternationalStandardizedProfile < Base
      def_delegators 'Pubid::Iso::Identifier::InternationalStandardizedProfile', :type

      TYPED_STAGES = {
        disp: {
          abbr: "DISP",
          name: "Draft International Standardized Profile",
          harmonized_stages: %w[40.00 40.20 40.60 40.92 40.93 40.98 40.99],
        },
        fdisp: {
          abbr: "FDISP",
          name: "Final Draft International Standardized Profile",
          harmonized_stages: %w[50.00 50.20 50.60 50.92],
        },
      }.freeze

      def self.type
        { key: :isp, title: "International Standardized Profile", short: "ISP" }
      end

      def self.get_renderer_class
        Renderer::InternationalStandardizedProfile
      end
    end
  end
end
