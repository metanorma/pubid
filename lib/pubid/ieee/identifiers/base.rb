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
      attribute :copublisher, :string, collection: true # IEC, ISO, ANSI, etc.
      # NB: there is deliberately NO `attribute :code`. IEEE's document code is
      # serialized as the split index columns (number/prefix/parts/separator) on
      # concrete leaf types via the CodeNumber mixin; `code`/`code_obj` remain a
      # runtime-only representation (built in #initialize, read by the renderer).
      # The separate AIEE/NESC/IRE identifier classes (which descend from
      # Lutaml::Model::Serializable, not this base) keep their own
      # `attribute :code`.
      attribute :year, :string
      attribute :type, :string, default: -> { "Std" } # Std, Draft Std
      attribute :draft_status, :string                    # Unapproved, Approved, Active Unapproved
      attribute :draft, :string                           # Will store draft as object
      attribute :edition, :string                         # Edition 1.0
      attribute :month, :string
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
      def initialize(args = {}, **kwargs)
        args = args.merge(kwargs) unless kwargs.empty?
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
          self.draft = args[:draft_obj].to_s
        elsif args[:draft].is_a?(String)
          self.draft_obj = Components::Draft.parse(args[:draft])
          self.draft = draft_obj.to_s
        elsif args[:draft]
          self.draft_obj = args[:draft]
          self.draft = args[:draft].to_s
        end

        # Set other attributes
        attrs = self.class.attributes
        args.each do |key, value|
          next if %i[code draft draft_obj typed_stage].include?(key)

          setter = :"#{key}="
          public_send(setter, value) if attrs.key?(key)
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

      # Inverse of the to_hash compaction: expand a scalar `stage` back into the
      # `typed_stage` sub-hash (on a deep copy, recursively) before lutaml
      # deserializes, so nested bases rebuild their component too. `draft` needs
      # no expansion (Draft.parse accepts the slashless form).
      def self.from_hash(data, options = {})
        data = Compaction.expand(Compaction.deep_dup(data)) if data.is_a?(::Hash)
        super
      end

      # Parse IEEE identifier string.
      #
      # PreParser owns all regex/dispatch logic; this method is a thin
      # orchestrator that consumes a PreParser::Result and routes to the
      # correct builder.
      def self.parse(input)
        if input.length > Pubid::MAX_INPUT_LENGTH
          raise ArgumentError, Pubid::INPUT_TOO_LONG_MESSAGE
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
        Identifiers::AdoptedStandard.new(
          ieee_identifier: aiee_id,
          adopted_identifier: asa_id,
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
        parsed = Parser.parse(normalized) # Use class method for preprocessing
        builder = Builder.new(Identifier)
        # Pass the original input string to builder for context
        builder.original_input = input
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
