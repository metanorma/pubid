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
      # Every printed type word (abbrev + English + French) → canonical code.
      TYPE_WORD_TO_CODE = TYPE_CODES.each_with_object({}) do |code, map|
        map[code] = code
        map[TYPE_NAME_EN[code]] = code
        map[TYPE_NAME_FR[code]] = code
      end.freeze

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
      # Metrologia journal fields.
      attribute :volume, :integer
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
        map "volume", to: :volume
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
        result
      end

      # Basic string representation. Delegates to renderer.
      def to_s(**opts)
        render(format: :human, **opts)
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
