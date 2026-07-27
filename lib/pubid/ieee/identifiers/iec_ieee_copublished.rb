# frozen_string_literal: true

module Pubid
  module Ieee
    module Identifiers
      # IEC/IEEE Copublished Identifier - standards copublished by IEC and IEEE.
      # Example: "IEC/IEEE 60079-30-2/D5 IEC:2013 (10/07)"
      #
      # The printed IEC/IEEE number is stored as split index columns rather than
      # a verbatim string: `number` (bare-digit narrowing key), `parts` (matched
      # within the bucket), `separators` (per-part `.`/`-`, since a single code
      # mixes them, e.g. `60076.57-1202`), and the trailing publication `year`
      # (inherited from the base; attached with `year_sep`, always `-` in
      # practice). The verbatim `copublished_number` is reconstructed from these
      # for rendering — see #copublished_number — so it is NOT serialized.
      class IecIeeeCopublished < Identifier
        attribute :number, :string
        attribute :parts, :string, collection: true, default: -> { [] }
        attribute :separators, :string, collection: true, default: -> { [] }
        attribute :year_sep, :string, default: -> { "-" }
        # `year` is inherited from the base (:string).

        attribute :iec_identifier, Identifier, polymorphic: true
        attribute :ieee_identifier, Identifier, polymorphic: true
        attribute :draft_info, :string          # Draft information like "/D5"
        attribute :iec_year, :string            # IEC year like "2013"
        attribute :date_info, :string           # Date information like "(10/07)"

        # The printed IEC/IEEE number, rebuilt losslessly from the split
        # columns (the renderer/urn read this). Not stored — number/parts/
        # separators/year fully describe it, so the verbatim string never
        # bloats an index row.
        def copublished_number
          return nil if number.to_s.empty?

          core = parts_suffix
          core += "#{year_sep}#{year}" if year
          "#{number}#{core}"
        end

        # The dotted/dashed parts portion, each part with its own separator.
        def parts_suffix
          separators.zip(parts).map { |sep, part| "#{sep}#{part}" }.join
        end

        # The base IEEE #exclude already nils year/month/day; also reset the
        # year separator (a format sibling of the scalar year, per the CSA
        # lesson) so a date-less reference matches a `:`-dated form too.
        def exclude(*args)
          result = super
          if args.intersect?(%i[year date]) && result.respond_to?(:year_sep=)
            result.year_sep = "-"
          end
          result
        end
      end
    end
  end
end
