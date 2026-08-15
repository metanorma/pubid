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
        # @param mark [String] IEEE trademark symbol, spliced in after the
        #   number and its parts and before the publication year (IEEE prints
        #   it there); "" for the ordinary, unmarked rendering.
        def copublished_number(mark = "")
          return nil if number.to_s.empty?

          code = marked_code(mark)
          code += "#{year_sep}#{year}" if year
          code
        end

        # The dotted/dashed parts portion, each part with its own separator.
        def parts_suffix
          separators.zip(parts).map { |sep, part| "#{sep}#{part}" }.join
        end

        # A stage word printed ahead of the number (`FDIS 60079-30-2`,
        # `CD2 P62704-5 ED1`, `TS P61869-105 ED1`). The lookahead — the next
        # token must start like a document number — is what stops this eating a
        # number that merely begins with a letter.
        STAGE_PREFIX = /\A[A-Z]+\d*\s+(?=P?\d)/

        # Inside the number token, the printed code stops early at:
        #
        # * a colon-attached publication year (`62582-2:2022`);
        # * a dash/dot-attached 19xx/20xx year (`62395.1-2024 Redline`) — only
        #   one a descriptive tail stranded inside the code gets here, since
        #   #peel_copublished_year moves a genuinely trailing year into the
        #   `year` attribute. The 19/20 prefix keeps a part that merely looks
        #   like a year (`60076.57-1202`) from matching;
        # * a glued parenthetical (`62704-1(E)`), which is a language marker
        #   rather than part of the number.
        CODE_END = /:\d{4}|[-.](?:19|20)\d{2}\z|\(/

        # `number` + #parts_suffix with the mark spliced at the end of the code
        # proper.
        #
        # Some copublished references carry an edition, a colon year, a stage
        # word or a "- Redline" tail that the parser keeps inside
        # `number`/`parts` rather than in dedicated attributes; appending the
        # mark after all of it would print
        # `IEC/IEEE 60076-16 Edition 2.0 2018-09™` instead of
        # `IEC/IEEE 60076-16™ Edition 2.0 2018-09`. Scanning the whole printed
        # code (not just the suffix) matters because the split point varies —
        # `60802 Edition 1` lands in `number`, `-16 Edition 2` in `parts`.
        #
        # With the flag off `mark` is "" and this returns the code unchanged, so
        # the plain rendering is byte-identical by construction.
        def marked_code(mark)
          code = "#{number}#{parts_suffix}"
          return code if mark.to_s.empty?

          at = code_end_index(code)
          "#{code[0...at]}#{mark}#{code[at..]}"
        end

        # Index at which the printed code ends and descriptive text begins.
        #
        # The number is the first whitespace-delimited token after any stage
        # word, so the code can never run past that token's end — which is what
        # keeps the mark off a trailing edition/date phrase even when no
        # CODE_END boundary matches inside the token.
        def code_end_index(code)
          start = code[STAGE_PREFIX]&.length || 0
          token_end = code.index(" ", start) || code.length
          boundary = code[start...token_end].index(CODE_END)
          boundary ? start + boundary : token_end
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
