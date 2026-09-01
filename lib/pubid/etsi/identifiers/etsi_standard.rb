# frozen_string_literal: true

module Pubid
  module Etsi
    module Identifiers
      # Single class for all ETSI standard types
      # Type is passed as parameter: EN, ES, EG, TS, ETR, ETS, I-ETS, TBR,
      # TCRTR, NET, GR, GS, SR, TR, GTS
      # Format: ETSI TYPE CODE VERSION (DATE)
      # Examples:
      #   ETSI GS ZSM 012 V1.1.1 (2022-12)
      #   ETSI GR ZSM 009-3 V1.1.1 (2023-08)
      #   ETSI GTS GSM 02.01 V5.5.0 (1999-01)
      class EtsiStandard < Identifier
        # Type is stored in @type attribute from Identifier
        # All rendering handled by Identifier class

        # --- Index columns -------------------------------------------------
        #
        # relaton-index sorts and bsearches every row on `id.root.number.to_s`,
        # so the document number must be reachable as `number`. ETSI used to
        # keep it inside an Etsi::Components::Code under a `code` attribute,
        # leaving the inherited `number` nil and every index row keyed "".
        #
        # The three Code fields are now plain sibling attributes, which is the
        # shape the serialized hash ALREADY had — the converters below merely
        # read them directly instead of reaching through `code`, so the wire
        # format is byte-identical and relaton-data-etsi's published index-v2
        # needs no regeneration.
        #
        # `number` holds the BARE number ("300 175"), never the part, so all
        # parts of a document share one index bucket and a part-less reference
        # finds them all — the IEEE/ISO semantics documented in CLAUDE.md.
        #
        # LANDMINE: these redeclare attributes inherited from ::Pubid::Identifier
        # (`number` is a Components::Code there, and Etsi::Components::Code is
        # NOT a subclass of it). That resolves nondeterministically under
        # multi-flavor load when declared on a class others inherit from, so it
        # is confined to this LEAF — EtsiStandard has no subclasses, while the
        # shared Pubid::Etsi::Identifier is also SupplementIdentifier's parent
        # and must stay untouched. spec/pubid/etsi/root_number_spec.rb carries
        # the tripwire and is only meaningful under the full `rake` suite.
        attribute :number, :string
        attribute :minor, :string
        attribute :parts, :string, collection: true, default: -> { [] }

        # Compact serialization (mirrors ISO/JCGM/OIML): the code fields are
        # bare scalars (`number`, a `parts` array and, rarely, a `minor`);
        # Version flattens to a scalar `version` string with an `is_edition`
        # boolean flag (omitted when false); Date flattens to top-level
        # year/month/day. The constant `publisher` ("ETSI") is intentionally
        # NOT mapped — it is reconstructed on load from its attribute default,
        # keeping the hash compact.
        #
        # This block lives on EtsiStandard (a leaf) rather than the shared Identifier:
        # SupplementIdentifier is a sibling that DELEGATES type/code/version and
        # date to its inner `base`, so a block on Identifier would be inherited-and-
        # merged by the supplement and re-emit every delegated field at the top.
        key_value do
          map "_type",      to: :_type
          map "type",       to: :type
          map "number",     to: :number
          map "parts",      to: :parts
          map "minor",      to: :minor
          map "version",    with: { to: :version_to_kv, from: :version_from_kv }
          map "is_edition", with: { to: :edition_to_kv, from: :edition_from_kv }
          map "year",       with: { to: :year_to_kv,  from: :year_from_kv }
          map "month",      with: { to: :month_to_kv, from: :month_from_kv }
          map "day",        with: { to: :day_to_kv,   from: :day_from_kv }
        end

        # The composed document code, rebuilt on demand from the split columns
        # so the renderer, the URN generator and #== keep one place to ask for
        # the printed form ("300 175-1"). Deliberately NOT an attribute and NOT
        # memoised: `number`/`parts` are writable (the base #exclude rebuilds
        # through them), so a cached Code would go stale.
        #
        # nil when there is no number, preserving the old nil-`code` semantics
        # the URN generator branches on.
        def code
          return nil if number.nil?

          Pubid::Etsi::Components::Code.new(
            number: number,
            minor: minor,
            parts: parts || [],
          )
        end

        # MR slug number segment.
        #
        # The base hook reads the inherited `number` and `part`; ETSI kept
        # neither, so before the index columns landed every ETSI slug was just
        # `etsi.<date>` — 454 distinct slugs for 24,724 documents, and
        # `to_slug` is what consumers use as an output FILENAME.
        #
        # Two things the base hook cannot do for ETSI:
        #   * the parts live in the `parts` collection, not the inherited
        #     scalar `part`, so they must be appended here or every part of a
        #     document collapses onto one slug;
        #   * an ETSI number legitimately contains a SPACE ("300 175", "GSM
        #     02.01"), which is outside the [a-z0-9.-] charset Renderers::MrString
        #     documents and guarantees. Sanitize BY CHARSET rather than by an
        #     enumerated escape list (the BIPM `mr_slug` precedent in
        #     CLAUDE.md), so a character added later cannot reach a filename.
        # `minor` is included because it is identity-bearing everywhere else —
        # Code#== compares it, Code#to_s renders it and the URN carries it — so
        # omitting it here would let two distinct documents share one filename.
        # No fixture populates it today; it is in the grammar, so it is here.
        def mr_number_with_part
          return nil if number.nil?

          mr_sanitize([number, minor, *Array(parts)].compact.join("-"))
        end

        # ETSI's identity is type + code + version + date (see
        # Pubid::Etsi::Identifier#==), so all four must reach the slug —
        # CLAUDE.md's rule that an identity-bearing marker has to appear on
        # every identity surface, not just in `==`. The base hooks find
        # neither: `mr_type` reads `typed_stage` (ETSI has none) and
        # `mr_edition` reads `edition.number` (ETSI models the edition as
        # `version`). Without these, "ETSI EN 300 729 V6.1.1 (2000-04)",
        # "…V7.1.1 (2000-04)" and "ETSI ETS 300 729 ed.2 (2000-04)" all share
        # one slug — i.e. one output filename.
        def mr_type
          type&.to_s&.downcase
        end

        def mr_edition
          mr_sanitize(version&.version)
        end

        # Segment sanitizer. Renderers::MrString joins SEGMENTS with ".", so a
        # dot inside one would break that structure — hence "." is replaced
        # here even though it is inside the renderer's overall charset (the
        # BIPM `bipm.si-brochure.9e-v3-01.e` precedent in CLAUDE.md). Filtering
        # by charset rather than by an enumerated escape list keeps a character
        # introduced later from leaking into a filename.
        #
        # Public purely to keep this file's surface flat, next to the
        # lutaml-invoked converters below — it has no external callers and
        # would work as well private.
        #
        # The emptiness check is on the OUTPUT, not just the input: a value
        # made entirely of characters outside the charset collapses to "-" and
        # then to "", and an empty string is truthy in Ruby, so it would reach
        # Renderers::MrString as a blank segment and produce a double dot in
        # the joined slug. Unreachable from today's grammar, which only feeds
        # digit/alnum captures here — but not structurally prevented.
        def mr_sanitize(value)
          return nil if value.nil? || value.to_s.empty?

          sanitized = value.to_s.downcase
            .gsub(/[^a-z0-9-]+/, "-").gsub(/\A-+|-+\z/, "")
          sanitized.empty? ? nil : sanitized
        end

        # --- Version flattened to scalar version + is_edition flag ---
        def version_to_kv(model, doc)
          emit_kv(doc, "version", model.version&.version)
        end

        def version_from_kv(model, value)
          version_for(model).version = value.to_s
        end

        def edition_to_kv(model, doc)
          return unless model.version&.is_edition

          doc.add_child(
            Lutaml::KeyValue::DataModel::Element.new("is_edition", true),
          )
        end

        def edition_from_kv(model, value)
          version_for(model).is_edition = value
        end

        # --- Date flattened to top-level year/month/day scalars ---
        def year_to_kv(model, doc)
          emit_kv(doc, "year", model.date&.year)
        end

        def month_to_kv(model, doc)
          emit_kv(doc, "month", model.date&.month)
        end

        def day_to_kv(model, doc)
          emit_kv(doc, "day", model.date&.day)
        end

        def year_from_kv(model, value)
          date_for(model).year = value.to_s
        end

        def month_from_kv(model, value)
          date_for(model).month = value.to_s
        end

        def day_from_kv(model, value)
          date_for(model).day = value.to_s
        end

        def emit_kv(doc, key, value)
          return if value.nil? || value.to_s.empty?

          doc.add_child(
            Lutaml::KeyValue::DataModel::Element.new(key, value.to_s),
          )
        end

        def version_for(model)
          model.version ||= Pubid::Etsi::Components::Version.new
        end

        def date_for(model)
          model.date ||= Pubid::Components::Date.new
        end
      end
    end
  end
end
