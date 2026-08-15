# frozen_string_literal: true

module Pubid
  module Itu
    # Base class for all ITU identifiers. Canonical name Pubid::Itu::Identifier.
    class Identifier < ::Pubid::Identifier
      # Parse an ITU identifier string into an identifier object.
      def self.parse(identifier)
        parsed = Parser.parse(normalize_whitespace(identifier))
        Builder.build(parsed)
      rescue Parslet::ParseFailed => e
        raise "Failed to parse ITU identifier '#{identifier}': #{e.message}"
      end

      # ITU's own listings occasionally carry a doubled space
      # ("ITU-T D.271  (10/2016)"). Whitespace is never significant in an ITU
      # identifier, so collapse runs of it rather than teaching every rule to
      # tolerate them. Any string over the shared input-length guard is left
      # untouched — `Pubid.parse` rejects it before this point, and the guard
      # exists precisely to keep long inputs away from regexes.
      def self.normalize_whitespace(identifier)
        return identifier unless identifier.is_a?(String)
        return identifier if identifier.length > ::Pubid::MAX_INPUT_LENGTH

        identifier.gsub(/[[:space:]]+/, " ").strip
      end
      private_class_method :normalize_whitespace

      # Long-form ↔ ITU single-letter language code map. The parser produces
      # single-letter codes (E/F/S/R/A/C); API callers (e.g. metanorma-itu)
      # pass long-form (en/fr/es/ru/ar/zh). Storage is normalized to the
      # single-letter form. Languages with no canonical letter (e.g. "de")
      # pass through unchanged and produce no trailing suffix.
      LANGUAGES = {
        "fr" => "F", "es" => "S", "ru" => "R",
        "ar" => "A", "zh" => "C", "en" => "E",
        "F" => "F", "S" => "S", "R" => "R",
        "A" => "A", "C" => "C", "E" => "E"
      }.freeze

      attribute :sector, Pubid::Itu::Components::Sector
      attribute :series, Pubid::Itu::Components::Series
      attribute :code, Pubid::Itu::Components::Code
      attribute :date, Pubid::Components::Date
      attribute :language, :string
      # "(V14)" of "ITU-T H.264 (V14) (08/2021)" — an ITU-T revision marker
      # distinct from the publication date. Declared here (not on the leaves)
      # because `render_base` lives here and the parser feeds it to both plain
      # and combined recommendations, and to the nested base of a supplement.
      # Safe from the number/stage redefinition landmine: ::Pubid::Identifier
      # declares no `version` attribute, so this is a new one, not a retype.
      attribute :version, :string
      # The literal word "series" of "ITU-T E-100 series Suppl. 1" and
      # "ITU-T E.1100 series Suppl. 1" — the document is the series group, not
      # one Recommendation within it. It cannot live inside `series` itself
      # because it also follows a *dotted* code, where folding it into the
      # series token would corrupt the value every index row is keyed on.
      # Named so the common case is the `false` default and stays out of
      # `to_hash`.
      attribute :series_word, :boolean, default: -> { false }
      # A series-code document joins its mnemonic series to its number with a
      # dash rather than a dot ("ITU-T EMC-5", "ITU-T SEC-QKD"). Keeping the
      # two halves split — rather than storing "EMC-5" in `series` — is what
      # keeps `root.number` non-empty for relaton-index. Named for the rare
      # form, so the dotted majority stays out of `to_hash`.
      attribute :series_dash, :boolean, default: -> { false }
      # "ITU-T H.350 attachment (08/2003)" — the machine-readable attachment
      # of a Recommendation, catalogued as its own record.
      attribute :attachment, :boolean, default: -> { false }
      # The upper bound of a Recommendation range published as one document —
      # "ITU-T Q.120-Q.139 (11/1988)", where this holds "Q.139". A plain string
      # rather than a structured designation: five legacy records, and the
      # printed form is the whole of their identity.
      attribute :range_end, :string
      attribute :common_text_twin, ::Pubid::Identifier

      def initialize(**kwargs)
        if kwargs[:language]
          kwargs = kwargs.merge(language: normalize_language(kwargs[:language]))
        end

        super

        validate_ob_no_sector!
      end

      # The document number lives on the `code` component for ITU; surface it at
      # the identifier root so consumers that key on `#number` — e.g.
      # Relaton::Index's sort/bsearch narrowing on `id.root.number.to_s` — work
      # without special-casing ITU. Returns the `code.number` string (e.g.
      # "530"); serialization is unaffected because the flat key_value block
      # maps "number" via `number_to_kv`/`number_from_kv`, which read/write
      # `code.number` directly and never touch the inherited `number` attribute.
      # Supplement/Amendment/Corrigendum/Errata declare their own `:string`
      # `number` (the ordinal), which overrides this reader; their base document
      # number is still reachable via `root.number`.
      def number
        code&.number
      end

      # ITU keeps the document number and its edition/part together inside one
      # Code component (like ETSI, unlike ISO's separate `part` attribute), so a
      # top-level exclude(:part) can't reach the part. Handle it during the
      # nested-exclusion pass: when :part/:parts is excluded, return a copy of
      # the Code with its parts cleared while keeping number/series/subseries.
      # This lets a part-less reference (e.g. `ITU-R P.838`) match every edition
      # (`ITU-R P.838-3`) via matches?(other, ignore: [:parts]). Any non-Code
      # value falls through to super, so nested identifiers (common_text_twin,
      # supplement `base`, combined `Designation`s) still recurse.
      def exclude_from_nested(value, args)
        part_keys = args & %i[part parts]
        if value.is_a?(Pubid::Itu::Components::Code) && !part_keys.empty?
          return Pubid::Itu::Components::Code.new(
            imp_marker: value.imp_marker,
            number: value.number,
            series_suffix: value.series_suffix,
            series_suffix_spaced: value.series_suffix_spaced,
            subseries: value.subseries,
            parts: [],
            qualifier: value.qualifier,
            qualifier_glued: value.qualifier_glued,
          )
        end

        super
      end

      # Generate URN for this identifier
      #
      # @return [String] URN representation

      # ITU encodes identity across `sector` (T/R/CD), `series` (G/H/J…), and
      # `code` (number with optional part), not in the inherited `number`/
      # `typed_stage`. The generic MrString renderer would otherwise drop all
      # three and emit just `ITU`. Losslessness for issue #142 requires the
      # sector letter, series letter, and document number to appear in MR.
      # Lowercased to match the all-lowercase MR convention.
      def mr_publisher
        publisher&.to_s&.downcase
      end

      def mr_type
        sector&.sector&.to_s&.downcase
      end

      def mr_number_with_part
        segments = []
        segments << series&.series&.to_s&.downcase if series&.series
        # The edition word and the qualifier letter are part of the document's
        # identity, so they must reach the slug: without them "D.200" and
        # "D.200 R" — and, worse, "Q.2931 B" and "Q.2931 C" — collapse onto
        # one MR string. They are glued to the number rather than given their
        # own "-" segment so they read as part of it ("x-50bis", "d-200r").
        number = code&.number&.to_s
        if number
          number += code.series_suffix.to_s if code.series_suffix
          number += code.qualifier.to_s.downcase if code.qualifier
          segments << number
        end
        segments << code&.subseries&.to_s if code&.subseries
        segments.concat(code&.parts&.map(&:to_s) || [])
        # Same reasoning as the suffixes above, and as the URN generator: these
        # three distinguish documents that otherwise slug identically.
        segments << "series" if series_word
        segments << "attachment" if attachment
        segments << "to-#{range_end.to_s.downcase.tr('.', '-')}" if range_end
        return nil if segments.empty?

        segments.join("-")
      end

      # Stored as a plain string (always "ITU") so it round-trips through
      # to_hash/from_hash. Was a `def publisher` method, which made lutaml
      # serialize a String against the Components::Publisher attribute.
      attribute :publisher, :string, default: -> { "ITU" }

      # Render identifier as a string.
      #
      # @param i18n_lang [Symbol, String] language for identifier text
      #   translation (e.g. :fr renders "Annex to" as "Annexe au"). Distinct
      #   from the identifier's `language` attribute, which is the document's
      #   own language and produces the trailing suffix like "-F".
      # @param language [Symbol, String] deprecated alias for i18n_lang.
      # @param format [Symbol] :long for title-style rendering of supported
      #   identifiers, otherwise the default short form.
      def to_s(**opts)
        opts = self.class.normalize_to_s_opts(opts)
        result = render_base(**opts) + render_language_suffix
        result += " | #{common_text_twin}" if common_text_twin
        result
      end

      def render_base(**_opts)
        result = "#{publisher}-#{sector}"

        # Add series and code. A series with no code is a series GROUP
        # ("ITU-T G-100 series"); without this branch it rendered a dangling
        # trailing dot.
        result += if series && code
                    " #{series}#{series_dash ? '-' : '.'}#{code}"
                  elsif series
                    " #{series}"
                  else
                    " #{code}"
                  end

        result += "-#{range_end}" if range_end
        result += " series" if series_word
        result += " attachment" if attachment

        # Add version marker if present — always between code and date
        result += " (V#{version})" if version

        result + render_date_suffix
      end

      # " (MM/YYYY)", or " (YYYY)" when the month is unknown; "" when undated.
      # Shared by every type that prints its date this way (Supplement and its
      # subclasses, CombinedIdentifier, AnnexOfRecommendation). NOT used by
      # SpecialPublication, which zero-pads its month.
      def render_date_suffix
        return "" unless date

        date.month ? " (#{date.month}/#{date.year})" : " (#{date.year})"
      end

      def render_language_suffix
        return "" unless language
        # Only render canonical single-letter ITU language codes
        # (e.g. "F", "S"). Languages with no mapping (e.g. "de") get
        # no suffix — matches v1 PR #38 render_language behavior.
        return "" unless LANGUAGES.value?(language)

        "-#{language}"
      end

      # Translate `language:` opt to `i18n_lang:` opt. v1 PR #38 introduced
      # `i18n_lang:` to disambiguate "rendering language" from the document
      # language attribute; `language:` remains a deprecated alias.
      def self.normalize_to_s_opts(opts)
        opts = opts.dup
        if opts.key?(:language) && !opts.key?(:i18n_lang)
          opts[:i18n_lang] = opts.delete(:language)
        else
          opts.delete(:language)
        end
        opts
      end

      def ==(other)
        return false unless other.is_a?(Pubid::Itu::Identifier)

        sector == other.sector &&
          series == other.series &&
          code == other.code &&
          date == other.date &&
          version == other.version &&
          # "the E.1100 series" is not Recommendation E.1100.
          series_word == other.series_word &&
          series_dash == other.series_dash &&
          attachment == other.attachment &&
          range_end == other.range_end &&
          language == other.language &&
          common_text_twin == other.common_text_twin
      end

      # --- Compact flat key_value converters (shared) --------------------
      # Collapse the identity components (Sector/Series/Code/Date) to bare
      # top-level scalars so the serialized hash is flat and index-friendly,
      # mirroring ISO/ETSI/JCGM/OIML. Used by the per-leaf key_value blocks
      # (see StandardSerialization) and by the Supplement/Annex/Combined
      # blocks. `publisher` ("ITU") is intentionally never mapped — it is
      # reconstructed from its attribute default.

      def sector_to_kv(model, doc)
        emit_kv(doc, "sector", model.sector&.sector)
      end

      def sector_from_kv(model, value)
        model.sector = Components::Sector.new(sector: value.to_s)
      end

      def series_to_kv(model, doc)
        emit_kv(doc, "series", model.series&.series)
      end

      def series_from_kv(model, value)
        model.series = Components::Series.new(series: value.to_s)
      end

      def imp_marker_to_kv(model, doc)
        emit_kv(doc, "imp_marker", model.code&.imp_marker)
      end

      def imp_marker_from_kv(model, value)
        code_for(model).imp_marker = value.to_s
      end

      def number_to_kv(model, doc)
        emit_kv(doc, "number", model.code&.number)
      end

      def number_from_kv(model, value)
        code_for(model).number = value.to_s
      end

      def series_suffix_to_kv(model, doc)
        emit_kv(doc, "series_suffix", model.code&.series_suffix)
      end

      def series_suffix_from_kv(model, value)
        code_for(model).series_suffix = value.to_s
      end

      # The three spelling/qualifier fields of Components::Code. The two
      # booleans emit only when true, so no already-published index row gains
      # a key; `qualifier` emits only when present.
      def series_suffix_spaced_to_kv(model, doc)
        return unless model.code&.series_suffix_spaced

        doc["series_suffix_spaced"] = true
      end

      def series_suffix_spaced_from_kv(model, value)
        code_for(model).series_suffix_spaced = value
      end

      def qualifier_to_kv(model, doc)
        emit_kv(doc, "qualifier", model.code&.qualifier)
      end

      def qualifier_from_kv(model, value)
        code_for(model).qualifier = value.to_s
      end

      def qualifier_glued_to_kv(model, doc)
        return unless model.code&.qualifier_glued

        doc["qualifier_glued"] = true
      end

      def qualifier_glued_from_kv(model, value)
        code_for(model).qualifier_glued = value
      end

      def subseries_to_kv(model, doc)
        emit_kv(doc, "subseries", model.code&.subseries)
      end

      def subseries_from_kv(model, value)
        code_for(model).subseries = value.to_s
      end

      def parts_to_kv(model, doc)
        parts = model.code&.parts
        return if parts.nil? || parts.empty?

        doc.add_child(
          Lutaml::KeyValue::DataModel::Element.new("parts", parts.map(&:to_s)),
        )
      end

      def parts_from_kv(model, value)
        code_for(model).parts = Array(value).map(&:to_s)
      end

      def year_to_kv(model, doc)
        emit_kv(doc, "year", model.date&.year)
      end

      def year_from_kv(model, value)
        date_for(model).year = value.to_s
      end

      def month_to_kv(model, doc)
        emit_kv(doc, "month", model.date&.month)
      end

      def month_from_kv(model, value)
        date_for(model).month = value.to_s
      end

      # Serialize a nested `base` identifier via its own to_hash so it collapses
      # to the compact shape, and re-dispatch through the flavor base on load so
      # `_type` resolves to the concrete subclass (a bare polymorphic cast would
      # rebuild a plain Identifier and lose the subclass). Mirrors ETSI/JCGM.
      def base_to_kv(model, doc)
        return unless model.base

        doc.add_child(
          Lutaml::KeyValue::DataModel::Element.new("base", model.base.to_hash),
        )
      end

      def base_from_kv(model, value)
        return unless value

        model.base = Pubid::Itu::Identifier.from_hash(value)
      end

      # The common-text twin ("| ISO/IEC 13818-1:2022") is another flavor's
      # identifier (ISO/IEC …); serialize it via its own flat to_hash and
      # reconstruct it cross-flavor through the top-level polymorphic router so
      # its concrete class (and custom mappings) are restored by `_type`.
      def common_text_twin_to_kv(model, doc)
        return unless model.common_text_twin

        doc.add_child(
          Lutaml::KeyValue::DataModel::Element.new(
            "common_text_twin", model.common_text_twin.to_hash
          ),
        )
      end

      def common_text_twin_from_kv(model, value)
        return unless value

        model.common_text_twin = ::Pubid::Identifier.from_hash(value)
      end

      def emit_kv(doc, key, value)
        return if value.nil? || value.to_s.empty?

        doc.add_child(
          Lutaml::KeyValue::DataModel::Element.new(key, value.to_s),
        )
      end

      def code_for(model)
        model.code ||= Components::Code.new
      end

      def date_for(model)
        model.date ||= Pubid::Components::Date.new
      end

      private

      def normalize_language(value)
        str = value.to_s
        LANGUAGES[str] || str
      end

      # OB (Operational Bulletin) is a cross-bureau ITU publication and
      # must not have a sector. Direct construction with both raises;
      # the parser silently drops sector for legacy strings like
      # "ITU-T OB.X" (handled in Builder).
      def validate_ob_no_sector!
        return unless series&.series == "OB"
        return if sector.nil?
        return if sector.is_a?(Components::Sector) && (sector.sector.nil? || sector.sector.to_s.empty?)

        raise ArgumentError,
              "OB (Operational Bulletin) is a cross-bureau ITU publication; " \
              "sector must not be set"
      end
    end

  end
end
