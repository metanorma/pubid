require_relative "../renderer/amendment"
require_relative "../renderer/urn-amendment"

module Pubid::Iso
  module Identifier
    class Amendment < Supplement
      def_delegators 'Pubid::Iso::Identifier::Amendment', :type

      TYPED_STAGES = {
        damd: {
          abbr: "DAM",
          legacy_abbr: %w[DAmd FPDAM],
          name: "Draft Amendment",
          harmonized_stages: %w[40.00 40.20 40.60 40.92 40.93 50.00 50.20 50.60 50.92],
        },
        fdamd: {
          abbr: "FDAM",
          legacy_abbr: %w[FDAmd],
          name: "Final Draft Amendment",
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
        { key: :amd, title: "Amendment" }
      end

      def self.get_renderer_class
        Renderer::Amendment
      end

      def urn
        raise Errors::NoEditionError, "Base document must have edition" unless base_has_edition?

        Renderer::UrnAmendment.new(get_params).render
      end
    end
  end
end
