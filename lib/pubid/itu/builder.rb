# frozen_string_literal: true

module Pubid
  module Itu
    class Builder
      def self.build(parsed_data)
        new.build(parsed_data)
      end

      def build(data)
        # "Annex to ..." identifier — wraps a Special Publication base
        if data[:annex_to]
          return build_annex(data[:annex_to])
        end

        # Common-text twin ("| ISO/IEC ..." suffix) — extract before building
        # the base ITU identifier, then attach to whichever class the base
        # resolves to.
        twin = parse_common_text_twin(data.delete(:common_text_twin))

        # Labelled annex of a Recommendation — "ITU-T A.23 Annex A (06/2014)".
        # The annexed document is the :base subtree; :year/:month at this level
        # are the annex's own date, not the base's.
        if data[:annex_number]
          annex = build_annex_of_recommendation(data)
          annex.common_text_twin = twin if twin
          return annex
        end

        # Labelled appendix of a Recommendation — "ITU-T G.101 App. I
        # (05/2000)". Same shape as the annex above.
        if data[:appendix_number]
          appendix = build_appendix_of_recommendation(data)
          appendix.common_text_twin = twin if twin
          return appendix
        end

        # Operational Bulletin (Special Publication) — series == "OB" or
        # legacy long form ("Operational Bulletin No. ...").
        # The series_dash guard keeps a series-code "ITU-T OB-1" out of this
        # branch, which would drop the dash and render it "ITU OB No. 1".
        # Belt-and-braces: `series_code_body` already refuses "OB" + dash, so
        # nothing reaches here with both set — the guard documents that coupling
        # so removing the parser's `absent?` fails loudly rather than silently
        # rerouting.
        if (data[:series].to_s == "OB" && data[:series_dash].nil?) ||
            data[:_op_bull]
          sp = build_special_publication(data)
          sp.common_text_twin = twin if twin && sp
          return sp
        end

        # Check if this is a supplement identifier
        if data[:supplement_type]
          supp = build_supplement(data)
          supp.common_text_twin = twin if twin && supp
          return supp
        end

        # Handbook — "ITU-R 42.HDB"
        if data[:handbook_marker]
          return build_handbook(data)
        end

        # Question — numeric ("ITU-R 234-1/7:") or letter-series
        # ("ITU-R P.3/BL/7"). Both carry a :study_group marker.
        if data[:study_group]
          return build_question(data)
        end

        # Build basic recommendation or combined identifier
        sector = Components::Sector.new(sector: data[:sector].to_s)
        series = Components::Series.new(series: data[:series].to_s) if data[:series]
        code = build_code(data) if data[:number]
        date = build_date(data) if data[:year]

        # Combined (joint) recommendation — one or more additional
        # "/SERIES.CODE" designations after the primary (e.g. "G.780/Y.1351",
        # "G.780/Y.1351/Z.1362"). The primary stays on the base series/code.
        if data[:combined]
          return Identifiers::CombinedIdentifier.new(
            sector: sector,
            series: series,
            code: code,
            combined: build_designations(data[:combined]),
            date: date,
            version: data[:version]&.to_s,
            # with_series offers these slots on either side of
            # combined_suffixes, so a joint id can carry them too; not
            # forwarding them let "ITU-T H.350/X.1 attachment" compare equal to
            # the un-attached document.
            series_word: !data[:series_word].nil?,
            series_dash: !data[:series_dash].nil?,
            attachment: !data[:attachment].nil?,
            range_end: data[:range_end]&.to_s,
            language: data[:language]&.to_s,
            common_text_twin: twin,
          )
        end

        # A Report ("Report ITU-R BT.2020-1") is shaped exactly like a
        # Recommendation — only the leading word, captured as :report_marker,
        # tells the two apart, and it has to, because the two series number
        # independently and the same series/number is two real documents.
        klass = data[:report_marker] ? Identifiers::Report : Identifiers::Recommendation

        klass.new(
          sector: sector,
          series: series,
          code: code,
          date: date,
          version: data[:version]&.to_s,
          series_word: !data[:series_word].nil?,
          series_dash: !data[:series_dash].nil?,
          attachment: !data[:attachment].nil?,
          range_end: data[:range_end]&.to_s,
          language: data[:language]&.to_s,
          common_text_twin: twin,
        )
      end

      # Parse the common-text twin string ("| ISO/IEC 13818-1:2022") into
      # the appropriate flavor's identifier object. Returns nil if the twin
      # is empty or unparseable.
      def parse_common_text_twin(twin_raw)
        return nil if twin_raw.nil?

        twin_str = twin_raw.to_s.strip
        # Strip a leading pipe if the parser captured it
        twin_str = twin_str.sub(/\A\s*\|\s*/, "")
        return nil if twin_str.empty?

        case twin_str
        when /\AISO\/IEC\b/, /\AISO\b/
          Pubid::Iso.parse(twin_str)
        when /\AIEC\b/
          Pubid::Iec.parse(twin_str)
        end
      rescue StandardError
        # If the twin doesn't parse as a known flavor, leave it as nil
        # rather than blowing up the whole parse — the ITU half is still
        # usable on its own.
        nil
      end

      # Build Special Publication (OB). Sector is silently dropped — OB is a
      # cross-bureau publication and `Identifier` rejects sector+OB
      # in its constructor.
      def build_special_publication(data)
        Identifiers::SpecialPublication.new(
          series: Components::Series.new(series: "OB"),
          code: data[:number] ? build_code(data) : nil,
          date: data[:year] ? build_date(data) : nil,
          language: data[:language]&.to_s,
        )
      end

      # Build "Annex to ..." identifier. The inner data is the Special
      # Publication; the annex inherits its language.
      def build_annex(inner_data)
        base = build_special_publication(inner_data)
        Identifiers::Annex.new(
          base: base,
          language: inner_data[:language]&.to_s,
        )
      end

      # Build a labelled annex of a Recommendation. sector/series/code are
      # deliberately NOT copied from the base: they are not serialized on the
      # wrapper, so copies would make a from_hash-rebuilt annex differ from the
      # parsed one.
      def build_annex_of_recommendation(data)
        Identifiers::AnnexOfRecommendation.new(
          base: build(data[:base]),
          number: data[:annex_number].to_s,
          date: data[:year] ? build_date(data) : nil,
          language: data[:language]&.to_s,
        )
      end

      # Build a labelled appendix of a Recommendation. Like the annex above,
      # sector/series/code are deliberately NOT copied from the base — they are
      # not serialized on the wrapper, so copies would make a from_hash-rebuilt
      # appendix differ from the parsed one.
      def build_appendix_of_recommendation(data)
        Identifiers::AppendixOfRecommendation.new(
          base: build(data[:base]),
          number: data[:appendix_number].to_s,
          material: data[:appendix_material]&.to_s,
          date: data[:year] ? build_date(data) : nil,
          language: data[:language]&.to_s,
        )
      end

      # Build Handbook ("ITU-R 42.HDB").
      def build_handbook(data)
        Identifiers::Handbook.new(
          sector: Components::Sector.new(sector: data[:sector].to_s),
          code: build_code(data),
          date: data[:year] ? build_date(data) : nil,
        )
      end

      # Build Question (numeric or letter-series).
      def build_question(data)
        series = if data[:series]
                   Components::Series.new(series: data[:series].to_s)
                 end

        Identifiers::Question.new(
          sector: Components::Sector.new(sector: data[:sector].to_s),
          series: series,
          code: build_code(data),
          study_group: data[:study_group].to_s,
          has_bl: !data[:has_bl].nil?,
          bracketed: !data[:bracketed].nil?,
          has_colon: !data[:question_colon].nil?,
        )
      end

      def build_supplement(data)
        # Build the base identifier first
        base = build(data[:base]) if data[:base]

        # Determine supplement type
        supplement_type = data[:supplement_type].to_s.gsub(".", "")
        klass = case supplement_type
                when "Amd"
                  Identifiers::Amendment
                when "Add"
                  Identifiers::Addendum
                when "Cor"
                  Identifiers::Corrigendum
                when "Err"
                  Identifiers::Errata
                when "Suppl"
                  Identifiers::Supplement
                else
                  # Previously fell through to a nil class and died with
                  # "undefined method 'new' for nil" one frame later. Any token
                  # added to Parser#supplement_type without a class here should
                  # say so.
                  raise ArgumentError,
                        "Unknown ITU supplement type: " \
                        "#{data[:supplement_type].inspect}"
                end

        # Build supplement date (separate from base date)
        supplement_date = if data[:supplement_year]
                            Pubid::Components::Date.new(
                              year: data[:supplement_year].to_s,
                              month: data[:supplement_month]&.to_s,
                            )
                          end

        # Sector/series are copied from the base when it has them; the fallback
        # to this level's own tokens is guarded because an annex base keeps
        # sector/series/code on *its* base, leaving all three nil here while the
        # supplement level carries no sector token of its own.
        # An annex base keeps sector/series/code on *its* base, so reach through
        # it via #root; otherwise a supplement of an annex would carry none of
        # them and its MR string would collapse to a bare "itu.<date>".
        base_identity = base&.sector ? base : base&.root
        sector = base_identity&.sector ||
          (Components::Sector.new(sector: data[:sector].to_s) if data[:sector])
        series = base_identity&.series ||
          (Components::Series.new(series: data[:series].to_s) if data[:series])

        attrs = {
          sector: sector,
          series: series,
          code: base_identity&.code,
          base: base,
          number: data[:supplement_number].to_s,
          # The marker is the captured space, so its ABSENCE is the flag.
          number_glued: data[:supplement_space].nil?,
          slash_joined: !data[:supplement_slash].nil?,
          date: supplement_date,
          language: data[:language]&.to_s,
        }
        # The "series" word rides on the supplement for the base-less,
        # series-only form; with a base it is the base's, and renders from
        # there. It is copied up anyway (like sector/series/code above) so the
        # supplement's own MR slug stays distinct — `render_supplement` and the
        # base-nil-guarded key_value/== only consult it when base is nil, so
        # the copy is render- and serialization-neutral.
        attrs[:series_word] = if base
                                !!base_identity&.series_word
                              else
                                !data[:series_word].nil?
                              end
        attrs[:technical] = true if data[:technical] &&
          klass == Identifiers::Corrigendum

        klass.new(**attrs)
      end

      private

      # Build the additional designations of a combined recommendation from the
      # repeated parse subtrees (each `{ designation: { series:, number:, … } }`).
      def build_designations(combined_data)
        Array(combined_data).map do |element|
          d = element[:designation] || element
          Components::Designation.new(
            series: Components::Series.new(series: d[:series].to_s),
            code: Components::Code.new(
              number: d[:number].to_s,
              series_suffix: d[:series_suffix]&.to_s,
              series_suffix_spaced: !d[:series_suffix_spaced].nil?,
              subseries: d[:subseries]&.to_s,
              parts: extract_parts(d[:parts]),
              qualifier: d[:qualifier]&.to_s,
              qualifier_glued: !d[:qualifier].nil? && d[:qualifier_spaced].nil?,
            ),
          )
        end
      end

      def build_code(data)
        Components::Code.new(
          imp_marker: data[:imp_marker]&.to_s,
          number: data[:number].to_s,
          series_suffix: data[:series_suffix]&.to_s,
          # The marker is the captured separating space, so its presence is
          # the flag for the edition word and its ABSENCE is the flag for the
          # qualifier letter (whose majority spelling is spaced).
          series_suffix_spaced: !data[:series_suffix_spaced].nil?,
          subseries: data[:subseries]&.to_s,
          parts: extract_parts(data[:parts]),
          qualifier: data[:qualifier]&.to_s,
          qualifier_glued: !data[:qualifier].nil? &&
            data[:qualifier_spaced].nil?,
        )
      end

      def build_date(data)
        Pubid::Components::Date.new(
          year: data[:year].to_s,
          month: data[:month]&.to_s,
        )
      end

      def extract_parts(parts_data)
        return [] unless parts_data

        parts = []
        if parts_data.is_a?(Array)
          parts_data.each do |part_hash|
            parts << part_hash[:part].to_s if part_hash[:part]
          end
        elsif parts_data.is_a?(Hash) && parts_data[:part]
          parts << parts_data[:part].to_s
        end

        parts
      end
    end
  end
end
