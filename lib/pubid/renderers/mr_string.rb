# frozen_string_literal: true

module Pubid
  module Renderers
    # Machine-readable string renderer.
    #
    # Produces a lossless, dot-separated, all-lowercase, filename-safe slug:
    #
    #   iso 9001:2015                       -> iso.9001.2015
    #   iso/iec 17031-1:2020                -> iso-iec.17031-1.2020
    #   iso 1234-1-2-3:2020                 -> iso.1234-1-2-3.2020
    #   iso/tr 14627:2017                   -> iso.tr.14627.2017
    #   iso 16634:--                        -> iso.16634.--
    #   iso 9001:2015/amd 1:2020            -> iso.9001.2015_amd.1.2020
    #   iso/iec 13818-1:2015/amd 3:2016/cor 1:2017
    #                                       -> iso-iec.13818-1.2015_amd.3.2016_cor.1.2017
    #
    # The renderer recurses into a supplement's `base` (one level per
    # `mr_supplement_suffix`) so chained Cor-Amd-IS structures render fully,
    # instead of every supplement layer collapsing onto its own
    # type/number/year and dropping the base (issue #142).
    #
    # Character set is restricted to [a-z0-9.-] plus `_` (supplement
    # separator), so `to_mr_string` doubles as a filesystem-/URL-safe slug.
    # `Identifier#to_slug` delegates here; NIST is the one flavor that
    # overrides `to_slug` because its MR shape is fixed by the pubid standard
    # and stays uppercase.
    class MrString < Base
      SEPARATOR_SUPPLEMENT = "_"

      # The flat MR segments, in order, as the hook each one reads. A hook
      # returning nil contributes no segment, so a flavor fills only the slots
      # its identity actually uses — `mr_volume` (ECMA) is nil everywhere else.
      SEGMENTS = %i[
        mr_publisher
        mr_type
        mr_number_with_part
        mr_year
        mr_edition
        mr_volume
        mr_languages
        mr_all_parts
      ].freeze

      def render(context: nil, **)
        suffix = @id.mr_supplement_suffix

        if suffix
          base = @id.base
          head = base ? self.class.new(base).render : ""
          head.empty? ? suffix : "#{head}#{SEPARATOR_SUPPLEMENT}#{suffix}"
        else
          render_flat(@id)
        end
      end

      private

      def render_flat(id)
        SEGMENTS.filter_map { |hook| id.public_send(hook) }.join(".")
      end
    end
  end
end
