# frozen_string_literal: true

module Pubid
  module Bipm
    # Base class for every BIPM identifier AND the flavor's parse/create entry
    # point — mirrors Pubid::Jis::Identifier. Concrete identifiers under
    # Pubid::Bipm::Identifiers descend from this class.
    #
    # BIPM has several unrelated document families (committee documents,
    # meetings, the Metrologia journal, the SI Brochure and its appendices,
    # mises en pratique, and Consultative-Committee guides) with no shared
    # numbering, so every family-specific attribute lives here as a flat,
    # nil-defaulted attribute and is used only by the classes that need it. The
    # canonical `to_hash` drops any attribute at its default/empty value, so an
    # unused attribute never appears in a family's serialized hash.
    class Identifier < ::Pubid::Identifier
      # Committee acronyms BIPM owns (JCGM excluded — see Pubid::Jcgm).
      GROUPS = %w[
        CIPM CGPM JCRB CCTF CCQM CCT CCL CCAUV CCU CCM CCEM CCPR CCRI
      ].freeze

      # Historic committee names consumer references still use. BIPM renamed the
      # CCDS (Comité Consultatif pour la Définition de la Seconde) to CCTF in
      # 1997 and the index keys the current name, so an alias is resolved at
      # parse time and never stored. Extend the map, not the parser, to add one.
      GROUP_ALIASES = { "CCDS" => "CCTF" }.freeze

      # Every group token the grammar accepts, current names and aliases alike.
      PARSEABLE_GROUPS = (GROUPS + GROUP_ALIASES.keys).freeze

      # Two-letter codes consumer references use for the one-letter language
      # codes BIPM prints. Resolved at parse time, so only "E"/"F" is stored.
      LANGUAGE_ALIASES = { "EN" => "E", "FR" => "F" }.freeze

      # Committee document type codes and their printed long-form names. Note
      # DECL prints as "Statement" in BOTH languages in the source data.
      TYPE_CODES = %w[REC RES DECN ACT DECL].freeze
      TYPE_NAME_EN = {
        "REC" => "Recommendation", "RES" => "Resolution",
        "DECN" => "Decision", "ACT" => "Action", "DECL" => "Statement"
      }.freeze
      TYPE_NAME_FR = {
        "REC" => "Recommandation", "RES" => "Résolution",
        "DECN" => "Décision", "ACT" => "Action", "DECL" => "Statement"
      }.freeze
      # Printed type words that are not the canonical name of their code. BIPM
      # prints DECL as "Statement" in both languages, but a reference spells the
      # word out; without these the parser matched "Declaration" and then mapped
      # it to NO code, so the renderer emitted a corrupt "CGPM  1 (1971)".
      TYPE_WORD_ALIASES = {
        "Declaration" => "DECL", "Déclaration" => "DECL"
      }.freeze

      # Every printed type word (abbrev + English + French + alias) → code.
      TYPE_WORD_TO_CODE = TYPE_CODES.each_with_object({}) do |code, map|
        map[code] = code
        map[TYPE_NAME_EN[code]] = code
        map[TYPE_NAME_FR[code]] = code
      end.merge(TYPE_WORD_ALIASES).freeze

      # Shared attributes (flat). Booleans/strings carry no default so they stay
      # nil and drop from the serialized hash unless set.
      attribute :group, :string
      attribute :type_code, :string # REC/RES/DECN/ACT/DECL (avoids base `type`)
      attribute :number, :string    # may be hyphenated ("10-1") or nil
      attribute :year, :integer
      attribute :language, :string  # "E"/"F"; nil = language-neutral
      # Surface style of committee documents: "short" (abbreviated key form) vs
      # "long" (full type-word name). Defaults to "short" so it drops from the
      # canonical hash for the indexed primary form.
      attribute :form, :string, default: "short"
      # Metrologia journal fields. `volume` is NOT stored — it is exactly the
      # index key, so MetrologiaArticle derives it from `number` (the IANA
      # `registry` / IETF `series` pattern) rather than serializing both.
      attribute :issue, :string # may be alphanumeric ("1A")
      attribute :article, :string
      # SI Brochure fields.
      attribute :edition, :string   # "9e"
      attribute :version, :string   # "v3.01"
      attribute :years, :string     # "2019/2024"
      # SI Brochure appendix/derived variant: "Appendix 3", "Concise", "FAQ".
      attribute :variant, :string
      # Mise en pratique (MEP) fields.
      attribute :mep_code, :string    # "S1", "KUPRTM"
      attribute :report_code, :string # MEP report variant: "BIPM-2019/05"
      # Consultative-Committee guide kind ("MeP"/"RSI"); group + number reused.
      attribute :guide_kind, :string
      # Full-content "Appendix N [Annex N] Part N.M" tail shared by MEP + guide
      # primary-docidentifier forms (nil for the bare short docnumber spelling).
      attribute :appendix, :string
      attribute :annex, :string
      attribute :part, :string

      # Attributes `Builder` derives `number` from for the families that have no
      # document number of their own. Excluding one of these has to clear
      # `number` too, or a wildcarded identifier would keep a stale index key —
      # the "reset the WHOLE cluster, not just the scalar" lesson CLAUDE.md
      # records for CSA's year and IEEE's year/month/day. `:volume` is listed
      # even though it is no longer an attribute: the base loop skips it, but
      # `exclude(:volume)` must still clear the key it derives from.
      NUMBER_SOURCE_ATTRIBUTES = %i[
        volume edition variant mep_code report_code
      ].freeze

      # Polymorphic type map for lutaml::Model key_value (de)serialization:
      # maps each subclass's polymorphic_name to its class name so a stored hash
      # rebuilds the correct identifier type via from_hash.
      BIPM_TYPE_MAP = {
        "pubid:bipm:committee-document" =>
          "Pubid::Bipm::Identifiers::CommitteeDocument",
        "pubid:bipm:meeting" => "Pubid::Bipm::Identifiers::Meeting",
        "pubid:bipm:metrologia-article" =>
          "Pubid::Bipm::Identifiers::MetrologiaArticle",
        "pubid:bipm:si-brochure" => "Pubid::Bipm::Identifiers::SiBrochure",
        "pubid:bipm:mep" => "Pubid::Bipm::Identifiers::Mep",
        "pubid:bipm:guide" => "Pubid::Bipm::Identifiers::Guide",
      }.freeze

      key_value do
        map "_type", to: :_type, polymorphic_map: BIPM_TYPE_MAP
        map "group", to: :group
        map "type_code", to: :type_code
        map "number", to: :number
        map "year", to: :year
        map "language", to: :language
        map "form", to: :form
        map "issue", to: :issue
        map "article", to: :article
        map "edition", to: :edition
        map "version", to: :version
        map "years", to: :years
        map "variant", to: :variant
        map "mep_code", to: :mep_code
        map "report_code", to: :report_code
        map "guide_kind", to: :guide_kind
        map "appendix", to: :appendix
        map "annex", to: :annex
        map "part", to: :part
      end

      # Publisher is always "BIPM". A plain constant (not a `publisher` method)
      # so it doesn't shadow the inherited lutaml `publisher` attribute, which
      # would otherwise fail serialization type validation.
      PUBLISHER = "BIPM"

      # French connective before a committee acronym: "de la" for the (feminine)
      # CGPM, "du" for every other (masculine) committee.
      def self.french_connective(group)
        group == "CGPM" ? "de la" : "du"
      end

      # Resolve a historic committee name to the name the index keys.
      def self.normalize_group(token)
        name = token.to_s
        GROUP_ALIASES.fetch(name, name)
      end

      # Resolve a two-letter language code to the one-letter code BIPM prints.
      def self.normalize_language(token)
        return nil if token.nil?

        code = token.to_s
        LANGUAGE_ALIASES.fetch(code, code)
      end

      def long?
        form == "long"
      end

      # BIPM keeps the publication year in its own `year` integer attribute
      # rather than the base `date` component, so the base #exclude's
      # :year->:date remap would nil the (unused) inherited `date` and leave
      # `year` intact. Clear `year` directly when either alias is excluded so
      # `matches?(row, ignore: [:year])` treats a partial (date-less) reference
      # as a year wildcard.
      def exclude(*args)
        result = super
        result.year = nil if args.include?(:year) || args.include?(:date)
        result.number = nil if args.intersect?(NUMBER_SOURCE_ATTRIBUTES)
        result
      end

      # Basic string representation. Delegates to renderer.
      def to_s(**opts)
        render(format: :human, **opts)
      end

      # --- MR string / slug -------------------------------------------------
      #
      # `to_slug` is what consumers use as an output FILENAME, so every BIPM
      # identifier needs a non-empty, filename-safe, non-colliding MR. None of
      # the base ::Pubid::Identifier hooks work here unchanged, because BIPM
      # models each of them with its own flat attribute rather than the shared
      # component the base expects. Each override below says which.
      #
      # The number segment and the family discriminator are supplied per leaf
      # (`mr_number_with_part` / `mr_type`), because BIPM's six families share
      # no numbering.
      #
      # Three deliberate collapses — MR is a canonical DOCUMENT slug, so
      # alternate print spellings of one document share it (the URN already
      # collapses the first two): `form` (short vs long committee spelling) and
      # the MEP/Guide `appendix`/`annex`/`part` full-content tail are omitted,
      # while `language` is kept because the E and F records are distinct
      # documents upstream.

      # BIPM keeps its publisher in the PUBLISHER constant rather than the
      # inherited `publisher` attribute (which would fail type validation), so
      # the base hook — `publisher&.to_s` — is nil. The JIS/IANA shape.
      def mr_publisher
        PUBLISHER.downcase
      end

      # BIPM stores the publication year in its own :integer attribute rather
      # than a Components::Date, so the base hook reads an unset `date`.
      def mr_year
        year&.to_s
      end

      # BIPM's `edition` is a plain :string ("9e"), not a Components::Edition,
      # so the base hook's `edition.number` raises NoMethodError. SiBrochure
      # folds the edition into its own number segment instead.
      def mr_edition
        nil
      end

      # BIPM has a single `language` string, not the base's `languages`
      # collection.
      def mr_languages
        language&.to_s&.downcase
      end

      # BIPM uses its own `type_code` attribute rather than a typed_stage, so
      # the base hook is always nil; the leaves supply the discriminator.
      def mr_type
        nil
      end

      # Join the parts of a number segment into one filename-safe token.
      #
      # The sanitisation is by CHARSET, not an enumerated escape list, so a
      # field added later cannot leak an unsafe character: everything outside
      # [a-z0-9] collapses to `-`. BIPM needs at least three of those today —
      # a `/` (the MEP report code "BIPM-2019/05"), a space (the SI Brochure
      # variant "Appendix 3") and a `.` (the brochure version "v3.01"). The
      # dot matters beyond filename safety: Renderers::MrString joins SEGMENTS
      # with ".", so a dot inside one would break the documented segment
      # structure.
      #
      # Caveat: `-` is both the intra-segment join and a substitute, so two
      # different field splits could in principle produce one slug. That
      # cannot happen with today's grammar — none of `group`, `guide_kind`,
      # `mep_code`, `issue` or `article` admits a `-`, and `number`'s own
      # internal `-` ("10-1") is unambiguous because the `group` before it
      # cannot contain one. A future hyphen-bearing free-text field would
      # need a different join.
      def mr_slug(*parts)
        slug = parts.compact.map(&:to_s).reject(&:empty?).join("-").downcase
        slug = slug.gsub(/[^a-z0-9]+/, "-").gsub(/\A-+|-+\z/, "")
        slug unless slug.empty?
      end

      # Parse a BIPM identifier string into an identifier object.
      # @param identifier [String] the BIPM identifier string
      # @return [Identifier] the appropriate identifier object
      # @raise [RuntimeError] if parsing fails
      def self.parse(identifier)
        if identifier.length > Pubid::MAX_INPUT_LENGTH
          raise ArgumentError, Pubid::INPUT_TOO_LONG_MESSAGE
        end

        # Normalize legacy/docnumber-style spellings before parsing
        # (data/bipm/update_codes.yaml), mirroring Pubid::Ccsds / Pubid::Plateau.
        normalized = Core::UpdateCodes.apply(identifier, :bipm)
        parsed = Parser.parse(normalized)
        Builder.build(parsed)
      rescue Parslet::ParseFailed => e
        raise "Failed to parse BIPM identifier '#{identifier}': #{e.message}"
      end
    end
  end
end
