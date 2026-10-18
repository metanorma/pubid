# frozen_string_literal: true

module Pubid
  module Ieee
    module Identifiers
      # Handles ISO/IEC/IEEE joint development identifiers
      # Supports bidirectional format conversion between IEEE and ISO representations
      #
      # Joint development standards can be represented in two formats based on lead party:
      #
      # IEEE-led Format (lead_party: "IEEE"):
      #   ISO/IEC/IEEE P26511/D8-2018
      #   - Publishers: ISO/IEC/IEEE (slash-separated)
      #   - Lead party: IEEE (drives development)
      #   - P prefix indicates IEEE project (draft)
      #   - /D8 indicates IEEE draft notation
      #   - Dash before year
      #
      # ISO-led Format (lead_party: "ISO"):
      #   ISO/IEC/IEEE FDIS 26511:2018
      #   - Publishers: ISO/IEC/IEEE (slash-separated)
      #   - Lead party: ISO (drives development)
      #   - ISO stage code (FDIS) instead of P/D notation
      #   - Colon before year
      #
      # Key principles:
      # - Lead party determines canonical format
      # - NO equivalence mapping (as per IEEE staff guidance)
      # - "P" prefix means IEEE project (any stage)
      # - ISO stages and IEEE drafts can coexist but are not equivalent
      # - Format conversion preserves semantic meaning within each system
      class JointDevelopment < Identifier
        # Split index columns (number/prefix/parts/separator) instead of a
        # `code` string, like every IEEE leaf — see CodeNumber. Rendering reads
        # `code` (base #code → code_obj), which CodeNumber rebuilds from the
        # split fields, so to_ieee_format / to_iso_format are unaffected.
        include CodeNumber

        attribute :publishers, :string, collection: true
        attribute :lead_party, :string              # "IEEE", "ISO", "IEC", etc.
        attribute :typed_stage, Components::TypedStage
        attribute :year, :string
        attribute :iso_stage, :string               # For ISO stage if present
        attribute :ieee_draft, :string              # For IEEE P/D notation if present
        attribute :parenthetical_content, :string   # e.g. the "(E)" edition
                                                    # marker of an ISO/IEC label

        # Accepts keyword args or a single positional hash (the base
        # #exclude/matching rebuild passes the latter) — see
        # Identifier#initialize.
        def initialize(args = {}, **kwargs)
          args = args.merge(kwargs) unless kwargs.empty?
          # Call super FIRST to initialize Lutaml::Model attributes
          super(args)

          # Then handle typed_stage
          if args[:typed_stage].is_a?(Components::TypedStage)
            self.typed_stage = args[:typed_stage]
          end

          # Set publishers
          if args[:publishers]
            self.publishers = args[:publishers]
          elsif args[:publisher] && args[:copublisher]
            # Combine publisher and copublisher into publishers array
            self.publishers = [args[:publisher], *args[:copublisher]].compact
          end

          # Set lead_party if not provided - default to first publisher
          if args[:lead_party]
            self.lead_party = args[:lead_party]
          elsif iso_stage
            # A stage-first reference is lead ISO, as the builder sets it
            # (pubid#477) — a hand-built id must agree with a parsed one.
            self.lead_party = "ISO"
          elsif publishers && !publishers.empty?
            # Lead party defaults to first publisher if not explicitly set
            # Builder should override this with detected lead party
            self.lead_party = publishers.first
          end
        end

        # Canonical format based on lead party
        # @return [Symbol] :ieee or :iso
        def canonical_format
          # A stage-tracked D= designator is IEEE draft notation — its
          # canonical face is the designator spelling (§1.3 spelling 7:
          # "JOINT PNUMBER/D=<STAGE>[:year]"), whatever the lead party.
          return :ieee if ieee_draft.to_s.start_with?("D=")

          case lead_party
          when "IEEE", "AIEE"
            :ieee
          when "ISO", "IEC"
            :iso
          else
            :ieee # default to IEEE format
          end
        end

        # Convert to string representation
        # JointDevelopment has its own dual-format logic (IEEE vs ISO)
        # that doesn't go through the format registry renderer.
        # @param format [Symbol] :ieee or :iso (defaults to canonical_format)
        # @param trademark [Boolean] append the IEEE trademark symbol (™/®)
        # @return [String] formatted identifier
        # `**_opts` absorbs render flags this list does not name (`annotated:`),
        # which the closed keyword list used to reject outright.
        def to_s(format: canonical_format, trademark: false, **opts)
          # The mark goes after the code number, before the draft and the year
          # ("ISO/IEC/IEEE P26511™/D8-2018"), so it is threaded into the
          # format builders rather than appended to the finished string.
          mark = if trademark
                   Pubid::Ieee.trademark_symbol_for(code&.number,
                                                    code&.prefix,
                                                    publishers: publishers)
                 else
                   ""
                 end

          result = case format
                   when :iso
                     to_iso_format(mark)
                   else
                     to_ieee_format(mark)
                   end

          annotate_plain_render(result, **opts)
        end

        private

        # Convert to ISO format representation
        # ISO/IEC/IEEE FDIS 26511:2018
        # @return [String] ISO format string
        def to_iso_format(mark = "")
          parts = []

          # Publishers (slash-separated)
          parts << publishers.join("/") if publishers && !publishers.empty?

          # The stage word is the ISO format's own position convention —
          # it prints whenever the identifier carries one, regardless of
          # lead party (the format face decides, not the arrangement).
          # The stage prints as stored, iteration included ("DIS2",
          # "CD4"): the face is lossless, so parse(to_s) == self
          # (pubid#477). A stage-tracked D= designator decomposes into its
          # stage word and date ("D=CD-2020" → "CD", 2020); the P project
          # stage is IEEE convention and never prints here.
          stage_word = iso_stage.to_s
          stage_word = nil if stage_word.empty?
          draft_year = nil
          if stage_word.nil? &&
             ieee_draft.to_s.match(/\AD=([A-Z]+)(?:\.(\d+[a-z]?))?(?:[-:](\d{4}))?\z/)
            stage_word = Regexp.last_match(1)
            draft_year = Regexp.last_match(3)
          end
          parts << stage_word if stage_word

          # The P project marker is identity-bearing and prints on both
          # faces (the standing trademark_leaf_to_s_spec contract:
          # "ISO/IEC/IEEE P26511:2018"). A P-prefixed joint project
          # prints its parts dot-joined on the ISO face ("ISO/IEEE DIS
          # P11073.10418", #216); a plain ISO/IEC number keeps the
          # printed separator ("IEC/IEEE FDIS 60079-30-2", "ISO/IEC
          # 8802-3").
          code_str = code.to_s
          code_str = code_str.tr("-", ".") if code_str.start_with?("P")
          code_str += mark unless code_str.empty?
          parts << code_str if code_str && !code_str.empty?

          # Join with space and add the date (a decomposed D= date rides
          # here as the year).
          result = parts.join(" ") + iso_date_suffix(year || draft_year)
          # The face is lossless: parse(to_s) == self (pubid#477; the
          # 2026-10-19 ruling). The bare language/edition marker ("(E)",
          # "(E/F)") and the trailing cross-reference narrative alike ride
          # the parenthetical slot — dropping the narrative emitted a
          # human the grammar rejects, so the round trip raised.
          result += " (#{parenthetical_content})" if parenthetical_content
          # The redline marker is identity — the joint ISO print spells it
          # with the space-dash form ("15289:2015(E) - Redline", pubid#215).
          result += " - Redline" if redline

          result
        end

        # The ISO-face date, in the spelling that parses back to the same
        # year and month: the colon year (":2018"); a numeric month glued
        # with dashes ("-2018-05"); a text month as ", February 2015".
        def iso_date_suffix(date_year)
          return "" unless date_year
          return ":#{date_year}" unless month

          if month.match?(/\A\d+\z/)
            # The grammar reads only a two-digit month ("05", never "5").
            "-#{date_year}-#{month.rjust(2, '0')}"
          else
            ", #{month} #{date_year}"
          end
        end

        # Convert to IEEE format representation
        # ISO/IEC/IEEE P26511/D8-2018
        # @return [String] IEEE format string
        def to_ieee_format(mark = "")
          parts = []

          # Publishers (slash-separated)
          parts << publishers.join("/") if publishers && !publishers.empty?

          # A status word ("Unapproved") marks the draft (pubid#318)
          parts << draft_status if draft_status

          # Build code part — the P-state prints as spelled (P = project
          # draft; no P = standard). Never added or stripped.
          code_str = code.to_s

          # Mark after the number, before the draft and the year
          code_str += mark unless code_str.empty?

          # Add IEEE draft notation if available (e.g., /D8). An ISO stage
          # word renders in IEEE's stage-tracked position as the ordinal-less
          # stage draft (docs/IEEE-DRAFT-STAGES.md §1.3, spelling 7) — only
          # on an explicit to_s(format: :ieee): a stage-first reference is
          # lead ISO, so its canonical face is the ISO one (pubid#477).
          # The iso_stage branch is checked FIRST — the typed_stage registry
          # lookup for a stage word answers a draft-equivalent ordinal ("D2"),
          # which is not the canonical stage-tracked spelling.
          if ieee_draft.to_s.start_with?("D=") && year
            # The ordinal-less stage draft's canonical face (the
            # UpdateCodes rewrite): the publication year colon-joins the
            # code and the designator trails — "P16326:2017/D=WD.5".
            code_str += ":#{year}"
            code_str += "/#{ieee_draft}"
            @designator_carries_year = true
          elsif ieee_draft
            code_str += "/#{ieee_draft}"
          elsif iso_stage
            # The ordinal-less stage draft: an iteration glued onto the
            # printed word ("CD2") renders in the doctrine's ".iter" slot
            # ("D=CD.2" — docs/IEEE-DRAFT-STAGES.md §1.3).
            stage = iso_stage.match(/\A([A-Z]+?)(\d+)\z/)
            code_str += stage ? "/D=#{stage[1]}.#{stage[2]}" : "/D=#{iso_stage}"
          elsif typed_stage&.ieee_draft_equivalent &&
                !code_str.start_with?(typed_stage.ieee_draft_equivalent)
            code_str += "/#{typed_stage.ieee_draft_equivalent}"
          end

          parts << code_str if code_str && !code_str.empty?

          # Join with space and add year with dash — unless the D=
          # designator face already carried it above.
          result = parts.join(" ")
          result += "-#{year}" if year && !@designator_carries_year &&
                           !ieee_draft.to_s.end_with?("-#{year}")
          # Lossless on the IEEE face too: the parenthetical rides after
          # the year, before the redline marker.
          result += " (#{parenthetical_content})" if parenthetical_content
          result += " - Redline" if redline

          result
        end

        # Public again: these override base accessors and MUST be public — lutaml
        # serialization calls `public_send(:publisher)`, so leaving them under the
        # `private` above made JointDevelopment#to_hash raise (it could not be
        # serialized or round-tripped / indexed at all).
        public

        # Override to ensure proper publisher handling
        def publisher
          publishers&.first || super
        end

        # Override to ensure proper copublisher handling
        def copublisher
          publishers&.drop(1) || super
        end

        # `publisher`/`copublisher` are *derived* from `publishers` (the source
        # of truth, which IS serialized). Emitting them too breaks the canonical
        # round-trip: the derived `publisher` is default-omitted on the parse
        # path but re-emitted after from_hash (the override returns
        # publishers.first, not the default). Drop both — publishers rebuilds
        # them. (JointDevelopment is a top-level root, never nested, so a
        # to_hash-level drop is sufficient.)
        def to_hash(*args)
          hash = super
          if hash.is_a?(::Hash)
            hash.delete("publisher")
            hash.delete("copublisher")
          end
          hash
        end
      end
    end
  end
end
