# frozen_string_literal: true

module Pubid
  module Itu
    module Identifiers
      # ITU Report — a publication series distinct from Recommendations.
      # Format: Report ITU-{SECTOR} {SERIES}.{NUMBER}[-EDITION]
      # Example: Report ITU-R BT.2020-1 (2000)
      #
      # Reports and Recommendations number INDEPENDENTLY, so the same
      # series/number/edition is two different documents — "ITU-R BT.2020-1" is
      # both Report BT.2020-1 (objective quality assessment, 2000) and
      # Recommendation BT.2020-1 (UHDTV parameter values, 06/2014). ITU
      # disambiguates them with the leading word, which is therefore part of
      # the identifier: the marker reaches `to_s`, `to_urn` and `to_mr_string`,
      # and the class-strict `Identifier#==` keeps the two unequal in both
      # directions so `#matches?` can never resolve one to the other.
      #
      # Everything else is shaped exactly like a Recommendation
      # (sector/series/code/date/version/language), including the flat
      # serialization — only `_type` distinguishes the two hashes.
      class Report < Identifier
        include StandardSerialization

        def render_base(**_opts)
          "Report #{super}"
        end

        # The MR string doubles as an output filename, so the marker has to
        # reach it too — otherwise a Report and its same-numbered
        # Recommendation slug identically and one overwrites the other.
        # "itu.r.report.bt-2020-1"
        def mr_type
          [super, "report"].compact.join(".")
        end
      end
    end
  end
end
