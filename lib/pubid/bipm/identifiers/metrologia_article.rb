# frozen_string_literal: true

module Pubid
  module Bipm
    module Identifiers
      # A Metrologia journal reference, at volume, volume+issue, or
      # volume+issue+article granularity. Issue may be alphanumeric ("1A") and
      # the article keeps its printed form ("06007", "S138").
      #
      # Printed forms (all round-trip):
      #   "Metrologia 51"          volume only
      #   "Metrologia 1 1"         volume + issue
      #   "Metrologia 51 1 128"    volume + issue + article
      class MetrologiaArticle < Identifier
        GROUP = "Metrologia"

        def self.type
          { key: :metrologia_article, web: :metrologia_article,
            title: "Metrologia Article", short: "metrologia-article" }
        end

        # MR: `bipm.metrologia[.<volume>[-<issue>[-<article>]]]`.
        # The volume IS the index key, so it is derived from `number` instead
        # of being stored beside it — storing both would duplicate the same
        # value in every one of the 6,204 published article rows. Kept as an
        # Integer because that is the public type consumers already read
        # (`Relaton::Bipm::Bibliography#id_hash` calls `pubid.volume`).
        #
        # Safe as a plain method only because `volume` is no longer a lutaml
        # attribute anywhere in the hierarchy — a method that shadows a
        # generated accessor corrupts attribute resolution (CLAUDE.md).
        def volume
          number&.to_i
        end

        def mr_type
          "metrologia"
        end

        # `number` is only the volume (it is the CLUSTERING relaton-index key),
        # so per-article distinctness has to come from here: the full triple.
        def mr_number_with_part
          mr_slug(volume, issue, article)
        end
      end
    end
  end
end
