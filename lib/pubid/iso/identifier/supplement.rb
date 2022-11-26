module Pubid::Iso
  module Identifier
    class Supplement < Base
      TYPED_STAGES = {}.freeze

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

      def base_has_edition?
        @base.base.nil? && !@base.edition.nil? || (!@base.base.nil? && !@base.base.edition.nil?)
      end

      def self.type
        :sup
      end
    end
  end
end
