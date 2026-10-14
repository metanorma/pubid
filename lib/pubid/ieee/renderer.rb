# frozen_string_literal: true

module Pubid
  module Ieee
    # Human-readable renderer for IEEE identifiers.
    #
    # Produces strings like:
    #   "IEEE Std 802.11-2020"
    #   "IEEE Std 535-2013/Cor. 1-2017"
    #   "ANSI C37.61-1973 and IEEE Std 321-1973"
    #
    # The renderer is registered as the +:human+ format in the IEEE format
    # registry and invoked via +render(format: :human)+.
    #
    # For wrapper types (DualPublished, AdoptedStandard, etc.) the renderer
    # composes child identifiers. For simple identifiers it delegates to the
    # identifier's own publisher/code/relationship helpers.
    class Renderer < ::Pubid::Renderers::Base
      def render(context: nil, **opts)
        # IEEE attaches the trademark mark to the document number, before the
        # year and every suffix ("IEEE Std 802.3®-2018"), so the mark is
        # emitted by whichever method renders the number rather than appended
        # to the finished string. A renderer instance is built per render call
        # (Pubid::Identifier#render), so the flag is safe as instance state.
        @trademark = opts[:trademark]

        result = render_id(@id)
        # The long face spells draft months out ("Aug" → "August") over the
        # bounded identifier — no title prose is ever in the string.
        result = expand_months(result) if @long
        result
      end

      # The long-form month names, longest key first ("Sept" before "Sep").
      LONG_MONTHS = {
        "Sept" => "September", "Jan" => "January", "Feb" => "February",
        "Mar" => "March", "Apr" => "April", "Jun" => "June",
        "Jul" => "July", "Aug" => "August", "Sep" => "September",
        "Oct" => "October", "Nov" => "November", "Dec" => "December",
      }.freeze
      private_constant :LONG_MONTHS

      # Expand abbreviated draft months to their long names (\b-bounded, so
      # only whole month tokens move).
      def expand_months(str)
        LONG_MONTHS.each do |abbr, full|
          str = str.gsub(/\b#{abbr}\b/, full)
        end
        str
      end

      private

      # Trademark mark for a document number, or "" when the flag is off.
      # @param number [String, nil] bare document number
      # @param prefix [String, nil] letter series of the code
      # @param publishers [Array<String>] printed publisher tokens — the ®
      #   series belongs to IEEE, not to another body numbering a document 802
      def mark(number, prefix = nil, publishers: nil)
        return "" unless @trademark

        Pubid::Ieee.trademark_symbol_for(number, prefix, publishers: publishers)
      end

      # The publisher tokens an identifier prints, for the ® decision.
      def publishers_of(id)
        return id.publishers if id.respond_to?(:publishers) && id.publishers

        copublishers = id.copublisher if id.respond_to?(:copublisher)
        [id.publisher, *copublishers].compact
      end

      # Compose a child identifier, propagating the trademark flag only when it
      # is safe. A foreign (non-IEEE) leaf may not accept the `trademark:`
      # keyword at all — Pubid::Nist's `to_s(format = :short)` would silently
      # swallow it as a positional Hash, and Pubid::Iso's would raise — and an
      # adopted or parenthetical child is not the IEEE document being marked.
      def child_to_s(child, **opts)
        return child.to_s(**opts) unless @trademark &&
          child.is_a?(Pubid::Ieee::Identifier)

        child.to_s(**opts, trademark: true)
      end

      # Dispatch to the type-specific renderer, returning the composed string
      # (each branch inserts the trademark mark at its own number boundary).
      def render_id(id)
        case id
        when Identifiers::DualPublished
          render_dual_published(id)
        when Identifiers::DualIdentifier
          render_dual_identifier(id)
        when Identifiers::AdoptedStandard
          render_adopted_standard(id)
        when Identifiers::RedlinedStandard
          render_redlined_standard(id)
        when Identifiers::Amendment
          render_amendment(id)
        when Identifiers::Corrigendum
          render_corrigendum(id)
        when Identifiers::InterpretationIdentifier
          render_interpretation(id)
        when Identifiers::ConformanceIdentifier
          render_conformance(id)
        when Identifiers::MultiNumberedIdentifier
          render_multi_numbered(id)
        when Identifiers::ParentheticalIdentifier
          render_parenthetical(id)
        when Identifiers::CsaDualPublished
          render_csa_dual_published(id)
        when Identifiers::IecIeeeCopublished
          render_iec_ieee_copublished(id)
        when Identifiers::SiStandard
          render_si_standard(id)
        when Identifiers::JointDevelopment
          child_to_s(id)
        else
          render_base(id)
        end
      end

      # ------------------------------------------------------------------
      # Base IEEE identifier rendering
      # ------------------------------------------------------------------

      def render_base(id)
        parts = []

        # Publisher(s) - handle copublisher array properly
        if id.copublisher && !id.copublisher.empty?
          parts << [id.publisher, *id.copublisher].join("/")
        else
          parts << id.publisher
        end

        # Draft status
        parts << id.draft_status if id.draft_status

        # Type - only render for IEEE/AIEE publishers, and only for non-projects.
        # A status word ("Unapproved") already marks the document as a draft,
        # so the WHOLE type word is dropped — not just "Std" (pubid#318: the
        # half-strip left "Draft" in the render, the re-parse dropped it, and
        # to_s needed three rounds to converge while losing the type).
        should_render_type = id.publisher&.match?(/^(IEEE|AIEE)/)

        if should_render_type && !id.typed_stage&.project_status && id.type && !id.type.to_s.strip.empty? && id.type != "P" &&
            !id.draft_status.to_s.match?(/unapproved/i)
          type_str = id.type.dup
          type_str = type_str.sub(/^P/, "") if type_str.start_with?("P")
          # A draft carries the word Draft alone in every face (the C2
          # ruling): Std/Standard never renders on a draft, whatever
          # spelling the source used — a status-less draft ("IEEE Draft
          # Std P802.3/D2.0") renders "IEEE Draft P802.3/D2.0".
          type_str = "Draft" if id.draft_obj && !id.draft_status
          # The long face expands the type word ("IEEE Standard 495-2007");
          # a draft never takes Std/Standard in any face, so the expansion
          # only ever sees the published word.
          type_str = "Standard" if @long && type_str == "Std"
          parts << type_str unless type_str.strip.empty?
        end

        # Code - with P prefix for projects (concatenated, not separated).
        # IEEE semantics (normative): P = project = the document is a
        # draft; no P = it has become a standard. The P-state is
        # identity-bearing, so the renderer never adds or drops it —
        # whatever the source spelling carries round-trips.
        if id.code_obj
          result = id.code_obj.to_s

          # Prepend P if this is a project AND code doesn't already have P.
          # A recorded project marker (the source spelled the P on a
          # non-IEEE-led publisher) prints regardless of the publisher.
          if (id.typed_stage&.project_status && should_render_type ||
              id.is_a?(Identifiers::ProjectDraftIdentifier) &&
              id.project_marker) && !result.start_with?("P")
            result = "P#{result}"
          end

          # Trademark mark — right after the number and its parts, before the
          # year, the revision, the draft and every other suffix.
          result += mark(id.code_obj.number, id.code_obj.prefix,
                         publishers: publishers_of(id))


          # A base year dash-attaches to the code when nothing else
          # carries it: no edition, no identity-month date - and either
          # no draft at all, or a draft that carries its OWN date (the
          # draft+corrigendum family: "PC37.09-1999/D7.2, Nov 2006" -
          # the 1999 is the base's year, the Nov 2006 the draft's).
          # A numeric identity month is the SHORT format: it keeps the
          # year on the code and appends itself dash-joined, whatever the
          # input spelling ("ANSI/IEEE 21-1976-11" and "IEEE P15026.1,
          # 05 2014" both render glued - pubid#517). The comma face is
          # the LONG format, a month name ("..., May 2014").
          glued_month = id.month.to_s.match?(/\A\d{1,2}\z/)
          year_on_code = id.year && !id.edition &&
                         (!id.month || glued_month) &&
                         (!id.draft_obj || id.draft_obj&.year)
          result += "-#{id.year}" if year_on_code
          result += "-#{id.month}" if glued_month

          # Append the numbered/lettered revision inline, in IEEE's native
          # position — right after the code number and before the draft
          # ("P802.16Rev2/D3"). Keeps a revision distinct from its base
          # standard. The lettered id keeps its printed separator
          # ("P802.11-REVmc" renders "P802.11-Revmc"); the bare word with
          # no id still prints "Rev" (pubid ruling 2026-10-14).
          result += "#{id.rev_sep}Rev#{id.revision}" if id.revision
          result += "#{id.rev_sep}Rev" if id.rev_bare

          # Append draft to code - with or without space based on original
          # format. An exactly-IEC/IEEE co-published reference prints only the
          # draft DESIGNATOR - a comma-separated project date ("IEC/IEEE
          # 61886-1/D2, May 2020" prints as "…/D2") is catalogue metadata, not
          # identity. Wider sets ("IEC/ISO/IEEE P82079-1/D1, June 2016") print
          # the date; a space-separated date always stays ("…/DCDV July 2015").
          # IEEE-published drafts normalize the comma date to the long form
          # ("D08, September, 2018").
          if id.draft_obj
            printed = id.draft_obj.to_s
            # The draft designator carries its date on every lead
            # (docs/IEEE-DRAFT-STAGES.md §3: "the draft designator with its
            # date" — the IEC/IEEE-led date-drop contradicted the DCD
            # convention and the raw records).
            if id.publisher == "IEEE" && id.draft_status.to_s.empty?
              # The long comma form is for dated project drafts; an
              # unapproved-draft render keeps its pinned single-comma form
              # (pubid#318 idempotence).
              printed = printed.sub(/, ([A-Z][a-z]+) (\d{4})\z/, ', \1, \2')
            end
            # A space-separated draft year with no print date trailing is
            # IEEE's dash form ("…/D1-2006"); with a trailing print date the
            # space stays ("…/D1 2004, Nov 2004").
            printed = printed.sub(/\A(D\d+) (\d{4})\z/, '\1-\2')
            result += id.space_before_draft ? " #{printed}" : printed
          end

          # Append interpretation notation (/INT)
          result += "/INT" if id.interpretation

          # Conformance is always built as a ConformanceIdentifier wrapper
          # (render_conformance), never inline on a base standard — the base no
          # longer carries a conf_number attribute.

          # Append ASHRAE joint publication (/ASHRAE Guideline NN-YYYY)
          if id.ashrae_number
            result += "/ASHRAE Guideline #{id.ashrae_number}"
            result += "-#{id.ashrae_year}" if id.ashrae_year
          end

          # Append IEEE cross-reference (/C62.22.1-1996)
          result += id.crossref if id.crossref

          parts << result
        elsif should_render_type && id.typed_stage&.project_status
          # No code but is a project - add standalone P
          parts << "P"
        end

        # Edition - with year if present (IEC style)
        if id.edition
          edition_str = "Edition #{id.edition}"
          if id.year
            edition_str += " #{id.year}"
            edition_str += "-#{id.edition_month}" if id.edition_month
          end
          parts << edition_str
        end

        # Build the main identifier (without month yet)
        result = parts.join(" ")


        # Month/Day - append directly to avoid extra space before comma.
        # An exactly-IEC/IEEE co-published reference drops the comma date
        # entirely (same catalogue-metadata rule as the draft date above):
        # "IEC/IEEE P60076-16, May 2016" prints as "IEC/IEEE 60076-16".
        if id.month && !glued_month &&
           !(id.publisher == "IEC" && id.copublisher == ["IEEE"])
          result += ", #{id.month}"
          result += " #{id.day}" if id.day
          if id.year && !id.edition
            result += " #{id.year}"
          end
        elsif id.year && id.draft_obj && !id.edition && !year_on_code &&
              !(id.publisher == "IEC" && id.copublisher == ["IEEE"])
          # A year-only date trailing the draft ("ANSI N42.34/D9a,
          # 2015") keeps its comma form - the grammar's comma-year
          # draft tail - instead of being silently dropped. A year
          # that dash-attached to the code above (the base year of a
          # dated-draft family) does not repeat here.
          result += ", #{id.year}"
        end

        # Bounded parenthetical markers only. The unbounded relationship/
        # amendment narrative (relationships, revision_of, amendment_to,
        # adoption, note) is deliberately NOT rendered here: an
        # "as amended by …" list can run 300+ chars, and an identifier's to_s
        # is used by consumers (relaton) as a document number and filename. The
        # narrative is preserved on the runtime accessors (id.relationships
        # etc.), just not embedded in the identifier string.
        parentheticals = []

        # Reaffirmation year — a bounded status marker.
        reaff = id.reaffirmed
        parentheticals << "(R#{reaff})" if reaff && !reaff.to_s.strip.empty?

        # The catch-all parenthetical is a bounded, printed identity token, not
        # relationship prose (e.g. the "S-135 (IPCEA P46-426)" co-designation).
        # Long amendment narratives match the structural relationship grammar
        # and land in `relationships`, never in this catch-all, so it stays
        # bounded.
        if id.parenthetical_content
          parentheticals << "(#{id.parenthetical_content})"
        end

        result += " #{parentheticals.join(' ')}" unless parentheticals.empty?

        # Book nickname - outside parentheses in square brackets
        result += " [#{id.nickname}]" if id.nickname && !id.nickname.to_s.strip.empty?

        # Redline suffix
        result += " - Redline" if id.redline

        result
      end

      # ------------------------------------------------------------------
      # Wrapper types
      # ------------------------------------------------------------------

      def render_dual_published(id)
        "#{child_to_s(id.first_identifier)} and " \
          "#{child_to_s(id.second_identifier)}"
      end

      def render_dual_identifier(id)
        "#{child_to_s(id.first_identifier)} and " \
          "#{child_to_s(id.second_identifier)}"
      end

      def render_adopted_standard(id)
        # Only the IEEE designation is marked; the adopted identifiers are
        # other bodies' documents (and may be foreign pubid objects).
        result = child_to_s(id.ieee_identifier)
        if id.adopted_identifiers && !id.adopted_identifiers.empty?
          adopted_strs = id.adopted_identifiers.map(&:to_s)
          result += " (#{adopted_strs.join(' and ')})"
        end
        result
      end

      def render_redlined_standard(id)
        result = child_to_s(id.base)
        # NOTE: currently unreachable — a redline is built as a flat
        # `redline: true` on a plain Standard (see the redline invariant in
        # CLAUDE.md), so determine_identifier_class never routes here. Kept for
        # completeness; if this path is ever revived, note `revision_of` is a
        # bounded single-id reference, unlike the unbounded relationship
        # narrative that render_base deliberately drops.
        result += " (Revision of #{id.revision_of})" if id.revision_of
        result += " - Redline" if id.redline
        result
      end

      def render_corrigendum(id)
        return render_base(id) unless id.base

        result = child_to_s(id.base)
        result += "/Cor"
        result += ". " if id.number # Add period and space for formal format
        result += id.number if id.number
        result += "-#{id.year}" if id.year
        result
      end

      def render_amendment(id)
        return render_base(id) unless id.base

        result = child_to_s(id.base)
        result += "/Amd"
        result += " #{id.number}" if id.number # canonical "/Amd 4-2020"
        result += "-#{id.year}" if id.year
        result
      end

      def render_interpretation(id)
        return render_base(id) unless id.base

        result = child_to_s(id.base)
        result += "/INT"
        result += "-#{id.year}" if id.year
        result
      end

      def render_conformance(id)
        return render_base(id) unless id.base

        result = child_to_s(id.base)
        result += "/Conformance#{id.number}" if id.number
        result += "-#{id.year}" if id.year
        result
      end

      def render_multi_numbered(id)
        return child_to_s(id.primary_identifier) unless id.secondary_identifier

        # Co-equal designations: each carries its own mark, before its own
        # suffixes, as IEEE prints them.
        primary = child_to_s(id.primary_identifier)
        secondary = child_to_s(id.secondary_identifier)

        secondary_code = id.secondary_identifier.code.to_s
        if secondary_code.start_with?("C") && secondary_code.match?(/^C\d+\./)
          # A cross-reference prints the bare second designation after the
          # slash — "IEEE Std 1299/C62.22.1-1996" — not a second full
          # reference, so this branch must not reuse `secondary`, which
          # carries its own "IEEE Std " prefix.
          "#{primary}/#{secondary_code}"
        else
          "#{primary} and #{secondary}"
        end
      end

      def render_parenthetical(id)
        # The mark belongs on the base; the parenthetical is a separate token.
        result = child_to_s(id.base)
        result += " (#{id.parenthetical_identifier})" if id.parenthetical_identifier
        result
      end

      def render_csa_dual_published(id)
        # csa_identifier is a Pubid::Csa object — never marked.
        csa_str = id.csa_identifier.to_s
        csa_str = "CSA #{csa_str}" unless csa_str.start_with?("CSA", "CAN/")

        "#{child_to_s(id.ieee_identifier)}/#{csa_str}"
      end

      def render_iec_ieee_copublished(id)
        result = "IEC/IEEE"
        # copublished_number glues the parts and the publication year onto the
        # number, so the mark is spliced in by that single implementation
        # rather than rebuilt here; with the flag off it is passed "".
        if id.copublished_number
          result += " #{id.copublished_number(mark(id.number,
                                                   publishers: %w[IEC IEEE]))}"
        end
        result += id.draft_info if id.draft_info
        result += " IEC:#{id.iec_year}" if id.iec_year
        result += " #{id.date_info}" if id.date_info
        result
      end

      def render_si_standard(id)
        parts = []

        # Publisher (IEEE/ASTM)
        parts << "IEEE/ASTM"

        # Type (SI or PSI based on typed_stage)
        parts << if id.typed_stage&.abbr&.include?("PSI")
                   "PSI"
                 else
                   "SI"
                 end

        # Code (number) with draft version for PSI — the mark goes after the
        # code, before the draft and the date.
        code_part = id.code.to_s
        code_part += mark(id.code_obj&.number, id.code_obj&.prefix,
                          publishers: publishers_of(id))
        if id.draft_obj
          code_part += "/D#{id.draft_obj.version}"
        end
        parts << code_part if id.code

        # Date
        if id.month && id.year
          parts << ", #{id.month} #{id.year}"
        elsif id.year
          parts << "-#{id.year}"
        end

        # Join parts with spaces, but don't insert a space before parts
        # that start with "-" or "," (e.g., "-2010", ", July 2014") so the
        # SI form renders as "SI 10-2010" not "SI 10 -2010". The descriptive
        # relationships narrative is deliberately kept out of to_s (see
        # render_base); it stays reachable on id.relationships.
        parts.each_with_object([]) do |part, acc|
          if acc.empty? || part.to_s.start_with?("-", ",")
            acc << part.to_s
          else
            acc << " " << part.to_s
          end
        end.join
      end
    end
  end
end
