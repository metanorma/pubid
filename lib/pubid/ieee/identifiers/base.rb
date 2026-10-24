# frozen_string_literal: true

module Pubid
  module Ieee
    module Components
      # Forward declare component classes
    end

    # Base class for all IEEE identifiers. Canonical name
    # Pubid::Ieee::Identifier. IEEE
    # builds its identifiers as instances of this class directly.
    class Identifier < ::Pubid::Identifier
      # Generate URN for this identifier
      #
      # @return [String] URN representation

      attribute :publisher, :string, default: -> { "IEEE" }
      # IEC, ISO, ANSI, etc. `initialize_empty` makes from_hash give `[]`, the
      # value a parsed identifier holds, so the two paths stay `==`.
      attribute :copublisher, :string, collection: true, initialize_empty: true
      # NB: there is deliberately NO `attribute :code`. IEEE's document code is
      # serialized as the split index columns (number/prefix/parts/separator) on
      # concrete leaf types via the CodeNumber mixin; `code`/`code_obj` remain a
      # runtime-only representation (built in #initialize, read by the renderer).
      # This holds for every IEEE type, including the historical AIEE/IRE and
      # the NESC family: all three used to descend from
      # Lutaml::Model::Serializable with their own `attribute :code`, and were
      # reparented onto this base (with the CodeNumber mixin on their leaves).
      attribute :year, :string
      attribute :type, :string, default: -> { "Std" } # Std, Draft Std
      attribute :draft_status, :string                    # Unapproved, Approved, Active Unapproved
      attribute :draft, :string                           # Will store draft as object
      # Numbered/lettered revision id, e.g. "2" for "P802.16Rev2", "i" for the
      # relaton suffix "/R-i". IEEE's native inline "Rev<n>" and relaton's
      # synthetic "/R-<x>" both feed this one attribute; rendered inline as
      # "Rev<id>". `::Pubid::Identifier` has no `revision` attribute, so this is
      # free of the number/stage multi-flavor collision landmine.
      attribute :revision, :string
      # The lettered revision's printed separator ("P802.11-REVmc" keeps its
      # dash; a glued "REVi" stays glued) and the bare-word marker (no id
      # after "Rev" — "802.1AR-Rev/D2.2" keeps "Rev"). pubid ruling
      # 2026-10-14.
      attribute :rev_sep, :string
      attribute :rev_bare, :boolean
      attribute :edition, :string                         # Edition 1.0
      attribute :month, :string
      # Provenance flag (pubid#517): the month arrived glued to the identity
      # year on the code ("ANSI/IEEE 21-1976-11", grammar
      # date_with_month_numeric) rather than as a trailing ", 11 1976"
      # print date. Serialization round-trips it so to_s reproduces the
      # glued face.
      attribute :month_glued, :boolean, default: -> { false }
      attribute :day, :string
      attribute :redline, :boolean, default: -> { false }
      attribute :amendments, Identifier, collection: true # Amendment identifiers
      attribute :corrigenda, Identifier, collection: true # Corrigendum identifiers
      attribute :revision_of, Identifier                  # Revision relationships
      attribute :incorporates, Identifier, collection: true # Incorporated documents
      attribute :supersedes, Identifier, collection: true # Superseded documents
      attribute :supplement_to, Identifier                # For supplements
      attribute :iso_identifier, :string # For IEC/IEEE formats
      attribute :parenthetical_content, :string           # Raw parenthetical content
      attribute :note, :string                            # Parenthetical notes
      attribute :adoption, :string                        # Adoption notes
      attribute :amendment_to, :string                    # Amendment to relationships
      attribute :edition_month, :string                   # Month part from Edition YYYY-MM
      attribute :space_before_draft, :boolean, default: -> {
        false
      } # Track space before /D
      attribute :typed_stage, Components::TypedStage # TYPED_STAGE integration
      attribute :relationships, Components::Relationship, collection: true # Relationship metadata
      attribute :nickname, :string # Book nickname (e.g., "[The Orange Book]")
      attribute :interpretation, :boolean, default: -> {
        false
      } # /INT notation
      attribute :ashrae_number, :string # ASHRAE Guideline number
      attribute :ashrae_year, :string # ASHRAE Guideline year
      attribute :crossref, :string # IEEE cross-reference (e.g., /C62.22.1-1996)
      attribute :reaffirmed, :string # Reaffirmed year (e.g., "2010" for (R2010))

      # Store actual component objects
      attr_accessor :code_obj, :draft_obj

      # Accept either keyword args (`new(number: "802")`, the normal path) or a
      # single positional attribute hash (`new({number: "802"})`). The latter is
      # what the base `Pubid::Identifier#exclude`/matching machinery uses when it
      # rebuilds via `self.class.new(attrs)`; without it, `exclude`/`matches?`
      # raised ArgumentError for every IEEE identifier.
      # Constructor parameters that are not lutaml attributes: `code` is
      # runtime-only (kept as `code_obj`), and the draft forms are turned into
      # component objects below.
      def self.extra_init_keys
        %i[code draft draft_obj]
      end

      def initialize(args = {}, **kwargs)
        args = args.merge(kwargs) unless kwargs.empty?
        # This override calls `super()` with no attributes and assigns through
        # setters instead, so it bypasses the base constructor's coercion and
        # unknown-key check. Apply them here to keep the cross-flavor contract.
        args = self.class.normalize_init_attributes(args)
        super()

        # Handle typed_stage if provided
        if args[:typed_stage]
          self.typed_stage = args[:typed_stage]
        end

        # Handle code as component object. `code` is runtime-only (not a lutaml
        # attribute) — we keep the parsed Components::Code in code_obj; every
        # leaf serializes the split index columns (number/prefix/parts/separator)
        # via the CodeNumber mixin instead of a `code` string. The renderer reads
        # code_obj (base #code returns it).
        if args[:code].is_a?(String)
          self.code_obj = Components::Code.parse(args[:code])
        elsif args[:code]
          self.code_obj = args[:code]
        end

        # Handle draft as component object
        if args[:draft_obj]
          self.draft_obj = args[:draft_obj]
          self.draft = args[:draft_obj].to_s.sub(%r{\A/}, "")
        elsif args[:draft].is_a?(String)
          self.draft_obj = Components::Draft.parse(args[:draft])
          self.draft = draft_obj.to_s.sub(%r{\A/}, "")
        elsif args[:draft]
          self.draft_obj = args[:draft]
          self.draft = args[:draft].to_s.sub(%r{\A/}, "")
        end

        # Set other attributes.
        #
        # A key the class accepts but does not declare as a lutaml attribute
        # (see `extra_init_keys`) is assigned through its plain accessor.
        # Without that, `CsaDualPublished#csa_identifier` — an `attr_accessor`
        # by design, "stored as-is (not a Lutaml model type)" — was never
        # assigned at all, and `renderer.rb` read nil from it:
        # `IEEE Std 844.1-2017/CSA C22.2 No. 293.1-17` rendered back as
        # `IEEE Std 844.1-2017/CSA`, losing the CSA designation entirely.
        attrs = self.class.attributes
        extra = self.class.extra_init_keys
        args.each do |key, value|
          next if %i[code draft draft_obj typed_stage].include?(key)

          setter = :"#{key}="
          if attrs.key?(key)
            public_send(setter, value)
          elsif extra.include?(key) && respond_to?(setter)
            public_send(setter, value)
          end
        end

      end

            # Override accessors to return component objects.

      def code
        code_obj
      end

      def draft
        draft_obj
      end

      # Lazily rebuild the parsed component objects from the underlying string
      # attributes. After from_hash, lutaml restores the :code/:draft strings
      # (@code/@draft) but not these objects; the renderer reads code_obj/
      # draft_obj directly, so rebuild on demand to render a deserialized
      # identifier identically to the parsed one. On the parse path code_obj/
      # draft_obj are already set, so the `||=` returns them unchanged.
      def code_obj
        @code_obj ||=
          (Components::Code.parse(@code.to_s) unless @code.nil? || @code.to_s.empty?)
      end

      def draft_obj
        @draft_obj ||=
          (Components::Draft.parse(@draft.to_s) unless @draft.nil? || @draft.to_s.empty?)
      end

      # Expose numeric month from draft if available
      def draft_month
        return nil unless draft_obj.is_a?(Components::Draft)

        draft_obj.numeric_month
      end

      # IEEE stores its publication date as separate `year`/`month`/`day`
      # :string attributes, not a Components::Date, so the base #exclude's
      # `:year`->`:date` remap can't reach them (it would nil an unused `date`
      # component and leave the strings). After the base rebuild, nil the whole
      # date cluster when `:year`/`:date` is excluded, so a date-less reference
      # matches every date in the bucket (relaton partial-ref matching). NB: the
      # base #exclude also previously raised for every IEEE id (positional
      # `self.class.new(attrs)` vs the keyword initialize) — fixed by
      # Identifier#initialize accepting a positional hash.
      def exclude(*args)
        result = super
        if args.intersect?(%i[year date])
          %i[year month day].each do |attr|
            result.public_send("#{attr}=", nil) if result.respond_to?("#{attr}=")
          end
        end
        result
      end

      # Compact the serialized hash (recursively, so nested Corrigendum bases
      # are compacted too) after the normal serialize + canonicalize: collapse
      # `typed_stage` to a scalar `stage` and strip the `/` off `draft`. See
      # Compaction for why this is a hash transform, not lutaml attributes.
      def to_hash(*args)
        hash = super
        Compaction.collapse(hash) if hash.is_a?(::Hash)
        hash
      end

      # Three more IEEE discriminators the default %i[date year edition
      # version] list misses, alongside `edition`/`year`: `revision` (e.g.
      # "2" in "P802.16Rev2"); `reaffirmed` (the "(R2010)" year, read by
      # renderer.rb and urn_generator.rb — two reaffirmations of the same
      # standard failed to collapse under #to_all_parts/#===); and
      # `edition_month`, the month half of "Edition N YYYY-MM"
      # (renderer.rb's `"Edition #{edition} #{year}-#{edition_month}"`),
      # which survived even though its sibling `year` is already stripped.
      def self.all_parts_edition_keys
        super + %i[revision rev_sep rev_bare reaffirmed edition_month]
      end

      # Inverse of the to_hash compaction: expand a scalar `stage` back into the
      # `typed_stage` sub-hash (on a deep copy, recursively) before lutaml
      # deserializes, so nested bases rebuild their component too. `draft` needs
      # no expansion (Draft.parse accepts the slashless form).
      def self.from_hash(data, options = {})
        data = Compaction.expand(Compaction.deep_dup(data)) if data.is_a?(::Hash)
        identifier = super
        # == compares the raw ivars: a rebuild whose lazy readers have not
        # run carries @code_obj/@draft_obj nil while a parse has them set,
        # so the objects compare unequal although their serialized hashes
        # agree (pubid#596). Materialize the runtime components eagerly.
        identifier.materialize_runtime_components
        identifier
      end

      # Rebuild the runtime components from the wire strings. Safe on every
      # construction path: the readers' ||= no-ops when already set, and the
      # CodeNumber rebuild covers the split-column rows that carry no code
      # string.
      def materialize_runtime_components
        code_obj
        draft_obj
        self
      end

      # Register the identifier classes the automatic `Identifiers::*` scan
      # cannot see, so `Pubid::Ieee::Identifier.from_hash` can route their rows
      # back. The scan only looks at classes declared *directly* under
      # `Identifiers`, which misses both AIEE and IRE (they live under their own
      # `Aiee`/`Ire` namespaces) and the whole NESC family (nested one level
      # deeper, under `Identifiers::Nesc`).
      def self.additional_identifier_classes
        [
          Aiee::Identifier,
          Ire::Identifier,
          Identifiers::Nesc::Draft,
          Identifiers::Nesc::Edition,
          Identifiers::Nesc::Handbook,
          Identifiers::Nesc::Preprint,
          Identifiers::Nesc::Redline,
          Identifiers::Nesc::Standard,
        ]
      end

      # Parse IEEE identifier string.
      #
      # PreParser owns all regex/dispatch logic; this method is a thin
      # orchestrator that consumes a PreParser::Result and routes to the
      # correct builder.
      def self.parse(input)
        unless input.is_a?(String)
          raise Pubid::Errors::InvalidInputError,
                Pubid::INPUT_NOT_A_STRING_MESSAGE
        end

        if input.length > Pubid::MAX_INPUT_LENGTH
          raise Pubid::Errors::InvalidInputError, Pubid::INPUT_TOO_LONG_MESSAGE
        end

        result = PreParser.preprocess(input)

        case result.dispatch
        when :aiee_simple
          return Aiee::Identifier.parse(result.input)
        when :iec_ieee_copublished
          return parse_single(result.input)
        when :dual_semicolon
          return build_dual(result.parts)
        when :dual_reaffirmed
          return build_reaffirmed(result)
        when :dual_ire
          return build_dual_with_reaffirmed(result)
        when :dual_space_separated
          return build_dual(result.parts)
        when :dual_and
          return build_dual(result.parts)
        when :dual_ampersand
          return build_dual(result.parts)
        when :aiee_asa_adoption
          return build_aiee_asa_adoption(result.parts)
        when :adopted
          return build_adopted(result.parts)
        else
          parse_single(result.input)
        end
      rescue Parslet::ParseFailed
        parse_single(input)
      end

      # ---- dispatch constructors (used by parse) ----

      def self.build_dual(parts)
        first = parse_single(parts[0])
        second = parse_single(parts[1])
        Identifiers::DualPublished.new(
          first_identifier: first,
          second_identifier: second,
        )
      end
      private_class_method :build_dual

      def self.build_reaffirmed(result)
        parsed = parse_single(result.input)
        parsed.reaffirmed = result.metadata[:reaffirmed] if parsed.class.attributes.key?(:reaffirmed)
        parsed
      end
      private_class_method :build_reaffirmed

      def self.build_dual_with_reaffirmed(result)
        ieee_id = parse_single(result.parts[0])
        ieee_id.reaffirmed = result.metadata[:reaffirmed] if ieee_id.class.attributes.key?(:reaffirmed)
        ire_id = parse_single(result.parts[1])
        Identifiers::DualPublished.new(
          first_identifier: ieee_id,
          second_identifier: ire_id,
        )
      end
      private_class_method :build_dual_with_reaffirmed

      def self.build_aiee_asa_adoption(parts)
        aiee_id = parse_single(parts[0])
        asa_id = parse_single(parts[1])
        # `adopted_identifierS` — AdoptedStandard declares a collection. The
        # singular spelling was not an attribute, so lutaml dropped it without
        # a word and the ASA half of these 13 identifiers was never stored:
        # `AIEE No 18-1934 (ASA C55 1934)` rendered back as `AIEE No 18-1934`.
        # The unknown-key contract turned that silent loss into a raise, which
        # is how it was found.
        Identifiers::AdoptedStandard.new(
          ieee_identifier: aiee_id,
          adopted_identifiers: [asa_id],
        )
      end
      private_class_method :build_aiee_asa_adoption

      def self.build_adopted(parts)
        ieee_id = parse_single(parts[0])
        adopted_parts = parts[1].split(",").map(&:strip)
        adopted_ids = adopted_parts.map do |part|
          if part.start_with?("IEC")
            Pubid::Iec.parse(normalize_iec_adoption(part))
          elsif part.start_with?("ANSI")
            Pubid::Ansi.parse(part)
          else
            parse_single(part)
          end
        end
        Identifiers::AdoptedStandard.new(
          ieee_identifier: ieee_id,
          adopted_identifiers: adopted_ids,
        )
      end
      private_class_method :build_adopted

      # "IEC 60255-24 Edition 2.0 2013-04" → "IEC 60255-24:2013-04 ED2.0"
      def self.normalize_iec_adoption(part)
        iec_part = part.dup
        iec_part.gsub!(/\s+Edition\s+([0-9.]+)\s+([0-9-]+)/, ':\2 ED\1')
        iec_part.gsub!(/\s+Edition\s+([0-9.]+)\s*$/, ' ED\1')
        iec_part
      end
      private_class_method :normalize_iec_adoption

      # Parse a single IEEE identifier
      def self.parse_single(input)
        # Apply legacy update_codes normalization first, before Parser's extensive preprocessing
        normalized = Core::UpdateCodes.apply(input, :ieee)
        # UpdateCodes may introduce the "; " double-label separator
        # ("ISO/IEC13210: 1994 (E) ANSI/IEEE Std ..." → the ISO/IEC and
        # IEEE labels of one document), but the dispatch ran on the raw
        # input - re-dispatch so the dual construction sees it.
        if normalized != input && normalized.include?("; ")
          result = PreParser.preprocess(normalized)
          return build_dual(result.parts) if result.dispatch == :dual_semicolon
        end
        parser_input = Parser.normalize_input(normalized)
        parsed = Pubid::Parg::Backend.parse(:ieee, parser_input)
        builder = Builder.new(Identifier)
        # Pass the original input string to builder for context
        builder.original_input = input
        builder.parser_input = parser_input
        builder.build(parsed)
      end

      # IEEE stores identity in `code` (prefix/number/parts) rather than the
      # generic `number`, has its own `type` string ("Std", "Draft Std"), and
      # carries `year` as a bare string — none of which the generic MrString
      # renderer knows about. Override the lossless MR template directly so
      # every IEEE identifier round-trips (issue #142). Supplements append
      # `_{type}.{number}.{year}` recursively via mr_supplement_suffix.
      # Lowercased to match the all-lowercase MR convention.
      def mr_publisher
        publisher&.to_s&.downcase
      end

      def mr_type
        type&.downcase
      end

      def mr_number_with_part
        code_obj&.to_s&.downcase
      end

      def mr_year
        year&.to_s
      end
    end

  end
end
