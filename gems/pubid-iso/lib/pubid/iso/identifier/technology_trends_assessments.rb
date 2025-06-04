require_relative "../renderer/technology_trends_assessments"

module Pubid::Iso
  module Identifier
    class TechnologyTrendsAssessments < Base
      def_delegators 'Pubid::Iso::Identifier::TechnologyTrendsAssessments', :type

      TYPED_STAGES = {
        dtta: {
          abbr: "DTTA",
          name: "Technology Trends Assessments Draft",
          harmonized_stages: %w[40.00 40.20 40.60 40.92 40.93 40.98 40.99],
        },
        fdtta: {
          abbr: "FDTTA",
          name: "Technology Trends Assessments Final Draft",
          harmonized_stages: %w[50.00 50.20 50.60 50.92 50.98 50.99],
        },
      }.freeze

      def self.type
        { key: :tta, title: "Technology Trends Assessments", short: "TTA" }
      end

      def self.get_renderer_class
        Renderer::TechnologyTrendsAssessments
      end
    end
  end
end
