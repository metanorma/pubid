module Pubid::Iso
  module Identifier
    class Corrigendum < Supplement
      def_delegators 'Pubid::Iso::Identifier::Corrigendum', :type

      TYPED_STAGES = {
        dcor: {
          abbr: "DCOR",
          name: "Draft Corrigendum",
          harmonized_stages: %w[40.00 40.20 40.60 40.92 40.93 50.00 50.20 50.60 50.92],
        },
        fdcor: {
          abbr: "FDCOR",
          name: "Final Draft Corrigendum",
          harmonized_stages: %w[50.00 50.20 50.60 50.92 50.98 50.99],
        },
      }.freeze

      def initialize(publisher: "ISO", number: nil, stage: nil, iteration: nil, supplement: nil,
                     joint_document: nil, tctype: nil, sctype: nil, wgtype: nil, tcnumber: nil,
                     scnumber: nil, wgnumber:nil,
                     dir: nil, dirtype: nil, year: nil, amendments: nil,
                     corrigendums: nil, type: nil, base: nil, supplements: nil, **opts)

        if base.year.nil? && base.stage.nil?
          raise Errors::SupplementWithoutYearOrStageError,
                "Cannot apply supplement to document without base identifier edition year or stage"
        end

        super
      end

      def self.type
        :cor
      end

      def self.get_renderer_class
        Renderer::Corrigendum
      end

      def urn
        raise Errors::NoEditionError, "Base document must have edition" unless base_has_edition?

        Renderer::UrnCorrigendum.new(get_params).render
      end
    end
  end
end
