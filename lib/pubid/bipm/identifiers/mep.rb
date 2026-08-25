# frozen_string_literal: true

module Pubid
  module Bipm
    module Identifiers
      # A mise en pratique (MEP) of an SI base-unit definition, and the related
      # BIPM report variant. Printed from the short docnumber form that relaton
      # uses as the index key — NOT the long "Appendix 2 Part x" content string.
      #
      # Printed forms (all round-trip):
      #   "SI MEP S1"              standard MEP code (unit letter + number)
      #   "SI MEP KUPRTM"          alphabetic MEP code
      #   "Rapport BIPM-2019/05"   report variant (mep_code absent, report_code set)
      class Mep < Identifier
        def self.type
          { key: :mep, web: :mep, title: "Mise en pratique", short: "mep" }
        end

        # MR: `bipm.mep.<code>`. Exactly one of `mep_code` / `report_code` is
        # set; the report code carries a `/` that `mr_slug` sanitises away. The
        # full-content "Appendix 2 Part x" tail is the same document, so it
        # stays out of the slug.
        def mr_type
          "mep"
        end

        def mr_number_with_part
          mr_slug(mep_code || report_code)
        end
      end
    end
  end
end
