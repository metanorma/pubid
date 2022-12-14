module Pubid::Iso
  module Identifier
    class InternationalStandard < Base
      def_delegators 'Pubid::Iso::Identifier::InternationalStandard', :type

      TYPED_STAGES = {
        dis: {
          abbr: "DIS",
          name: "Draft International Standard",
          harmonized_stages: %w[40.00 40.20 40.60 40.92 40.93],
        },
        fdis: {
          abbr: "FDIS",
          name: "Final Draft International Standard",
          harmonized_stages: %w[50.00 50.20 50.60 50.92 50.98 50.99],
        },
      }.freeze

      def initialize(publisher: "ISO", number: nil, stage: nil, iteration: nil, supplement: nil,
                     joint_document: nil, tctype: nil, sctype: nil, wgtype: nil, tcnumber: nil,
                     scnumber: nil, wgnumber:nil,
                     dir: nil, dirtype: nil, year: nil, amendments: nil,
                     corrigendums: nil, type: nil, base: nil, supplements: nil, **opts)

        if iteration && stage.nil?
          raise Errors::IsStageIterationError, "IS stage document cannot have iteration"
        end

        super
      end


      def self.type
        :is
      end
    end
  end
end
