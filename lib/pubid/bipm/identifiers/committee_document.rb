# frozen_string_literal: true

module Pubid
  module Bipm
    module Identifiers
      # A committee document: a Recommendation (REC), Resolution (RES),
      # Decision (DECN), Action (ACT) or Declaration (DECL) issued by one of the
      # BIPM committees.
      #
      # Printed forms (all round-trip):
      #   "CCTF REC 2 (2012)"              short, language-neutral
      #   "CCTF REC 2 (2012, E)"           short, with language
      #   "CGPM DECL (1889)"               number-less
      #   "CCL Recommendation 1 (2001)"    full English name  (form: "long")
      #   "Recommandation 1 du CCL (2001)" full French name   (form: "long")
      class CommitteeDocument < Identifier
        def self.type
          { key: :committee_document, web: :committee_document,
            title: "Committee Document", short: "committee-document" }
        end

        # MR: `bipm.<type>.<group>-<number>.<year>[.<lang>]`. The type code
        # discriminates REC/RES/DECN/ACT/DECL; the bare CIPM MRA form has none.
        def mr_type
          type_code&.downcase
        end

        # The group has to be in the number segment or `CCTF REC 2` and
        # `CCEM REC 2` would share a slug.
        def mr_number_with_part
          mr_slug(group, number)
        end
      end
    end
  end
end
