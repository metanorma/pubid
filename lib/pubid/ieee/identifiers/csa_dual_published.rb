# frozen_string_literal: true

module Pubid
  module Ieee
    module Identifiers
      # CSA dual published identifier
      # Represents IEEE/CSA dual published standards
      # Example: IEEE Std 844.1-2017/CSA C22.2 No. 293.1-17
      class CsaDualPublished < Identifier
        attribute :ieee_identifier, Identifier
        # CSA identifier is stored as-is (not a Lutaml model type)
        attr_accessor :csa_identifier

        # Walk to the IEEE designation for the relaton-index key: this wrapper
        # names one document by an IEEE and a CSA number and holds neither
        # itself, so `root.number` was "".
        def root
          ieee_identifier ? ieee_identifier.root : self
        end

        # Carry the number onto the URN and the MR slug as well as #root — see
        # AdoptedStandard#code_obj. `#code` below delegates already, but the
        # URN generator and the MR renderer both read `code_obj`.
        def code_obj
          ieee_identifier&.code_obj
        end

        # Delegate common attributes to ieee_identifier
        def publisher
          ieee_identifier.publisher
        end

        def copublisher
          ieee_identifier.copublisher
        end

        def code
          ieee_identifier.code
        end

        def year
          ieee_identifier.year
        end

        def typed_stage
          ieee_identifier.typed_stage
        end

        def self.parse(string)
          Identifier.parse(string)
        end
      end
    end
  end
end
