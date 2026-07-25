# frozen_string_literal: true

module Pubid
  module Nist
    # NIST/NBS flavor base class. Canonical name Pubid::Nist::Identifier; every
    # concrete NIST identifier (Identifiers::*) descends from it. Being a real Pubid::Identifier subclass gives
    # native `is_a?` identity and the shared polymorphic `from_hash`.
    class Identifier < ::Pubid::Identifier
      # Delegate to the flavor module so callers can use
      # `Pubid::Nist::Identifier.parse` consistently with other flavors.
      def self.parse(identifier)
        Pubid::Nist.parse(identifier)
      end

      # Default: no typed stages. Subclasses override as needed.
      def self.typed_stages
        []
      end

      # Generate URN for this identifier
      #
      # @return [String] URN representation

      # Plain string ("NIST"/"NBS"), not a Components::Publisher wrapper: the
      # value is a single token, so a string serializes flat
      # (`publisher: NBS`, not `publisher: {publisher: NBS}`) and accepts the
      # raw string the circular/supplement builders pass straight through.
      attribute :publisher, :string
      attribute :series, Components::Code # Set by Builder from parsed data
      # SP subseries (Appendix A.2 of the NIST PubID Syntax): for "NIST SP 800-53"
      # the subseries is "800" and the sequence is "53". Populated by the Builder
      # when the series is "SP" and the first number matches a known subseries
      # code. Informational metadata derived from series+number — ignored in
      # equality so a manually-built id (without subseries set) still equals a
      # parsed one.
      attribute :subseries, Components::Code
      attribute :number, Components::Code

      # V2 COMPONENTS (Lutaml::Model objects) - PROPER SEPARATION
      attribute :edition, Components::Edition # Edition (type + id): e2, e2021, r5, -3
      attribute :edition_component, Components::Edition # V2 edition component (alias)
      attribute :volume, Components::Volume # Volume component (v6)
      attribute :part, Components::Part  # Part component (n1 or pt1)
      attribute :stage, Components::Stage
      attribute :version_component, Components::Version
      attribute :update_component, Components::Update
      attribute :translation_component, Components::Translation
      attribute :issue_number, Components::IssueNumber
      attribute :parsed_format, :string  # :mr, :short, :long, :abbrev
      # Whether the publisher prefix (NIST/NBS) should be rendered. Defaults
      # to true so the common publisher-bearing id need not serialize the
      # flag at all — the Builder only assigns it (false) for prefix-less
      # inputs, so `to_hash` carries `publisher_was_parsed: false` only in
      # that case and omits it otherwise. (lutaml emits a boolean iff it was
      # explicitly assigned; an omitted key loads as this default.)
      attribute :publisher_was_parsed, :boolean, default: -> { true }

      # LEGACY attributes (keep for backward compatibility during migration)
      attribute :parts, Components::Code, collection: true
      attribute :revision, :string
      attribute :revision_year, :string # Year for revision (e.g., r6/1925, r1963, rJun1992)
      attribute :revision_month, :string # Month for revision (e.g., rJun1992)
      attribute :edition_year, :string # Legacy edition year for backward compatibility
      attribute :version, :string
      attribute :update, Components::Update
      attribute :year, :integer
      attribute :month, :integer

      # Additional attributes for complex patterns
      attribute :first_number, Components::Code
      attribute :second_number, Components::Code
      attribute :update_number, :string
      attribute :update_year, :string
      attribute :addendum, :string
      attribute :addendum_number, :string
      # Single source of truth for the supplement: a structured component with
      # isolated parts (number / year / month / date-range / revision), so a
      # supplement's year is queryable independently of its number. Presence
      # (non-nil) means "is a supplement"; an all-empty component is a bare
      # "sup" marker. Replaces the former flat :supplement string plus the
      # separate date-range/has_revision fields.
      attribute :supplement, Components::Supplement
      attribute :errata, :string
      attribute :index, :string
      attribute :insert, :string
      attribute :section, :string
      attribute :appendix, :string
      attribute :translation, :string
      attribute :draft, :string
      attribute :draft_number, :string # For -draft N → N pd rendering

      # Default series_code — subclasses override to provide a normalized series name.
      def series_code
        nil
      end

      def initialize(**attributes)
        super()

        attrs = self.class.attributes
        attributes.each do |key, value|
          next if value.nil?

          setter = :"#{key}="
          public_send(setter, value) if attrs.key?(key)
        end

        # NOTE: Compound number building is handled by the Builder class
        # Do NOT build compound numbers here - let the builder apply special patterns first
        # See lib/pubid/nist/builder.rb lines 368-472 for compound number logic
      end

      # Attributes that are build artifacts or rendering aliases, not part
      # of an identifier's logical identity. They diverge between equally-
      # valid spellings of the same id (e.g. long "Rev. 1" vs short "r1"):
      #   - edition_component: redundant alias of :edition
      #   - first_number/second_number: decomposed parts of the canonical
      #     :number, retained from the parse for building
      #   - parsed_format: records the input format for round-trip rendering
      #   - subseries: derived from series+number (which SP subseries the
      #     document belongs to); populated by the Builder for known SP
      #     subseries codes. Ignored in equality so a manually-built id
      #     without subseries set still equals a parsed one.
      EQUALITY_IGNORED_ATTRS = %i[
        edition_component first_number second_number parsed_format subseries
      ].freeze

      # Logical identity comparison: equal when every attribute except the
      # build artifacts/aliases above matches. (Edition#== already ignores
      # its rendering-only original_prefix.)
      def ==(other)
        return false unless other.instance_of?(self.class)

        self.class.attributes.each_key.all? do |name|
          EQUALITY_IGNORED_ATTRS.include?(name) || public_send(name) == other.public_send(name)
        end
      end

      alias eql? ==

      def hash
        vals = self.class.attributes.each_key.reject do |name|
          EQUALITY_IGNORED_ATTRS.include?(name)
        end.map { |name| public_send(name) }
        [self.class, *vals].hash
      end

      # Wildcard / partial-identifier match. Treats +self+ as a QUERY pattern
      # and +candidate+ as a concrete document: every ID part SET on the query
      # must equal the candidate's, while parts left unset (nil/empty) are
      # wildcards that match any value. So a query carrying no edition and no
      # supplement matches that document across ALL editions, years, and
      # supplements — the basis for "select docs by ID parts".
      #
      # Asymmetric (unlike ==): "NBS CIRC 25".matches?("NBS CIRC 25sup1924")
      # is true, but not the reverse. The candidate must be the same class or
      # a subclass so series-level identity still holds.
      def matches?(candidate)
        return false unless candidate.is_a?(self.class)

        self.class.attributes.each_key.all? do |name|
          next true if EQUALITY_IGNORED_ATTRS.include?(name)

          query_val = public_send(name)
          next true if query_val.nil?
          next true if query_val.is_a?(String) && query_val.empty?
          next true if query_val.is_a?(Array) && query_val.empty?

          query_val == candidate.public_send(name)
        end
      end

      # NIST inherits Pubid::Identifier#exclude directly: it now rebuilds via
      # `self.class.new(**attrs)`, so NIST's keyword-only initialize
      # (initialize(**attributes)) works without a local override, and the base
      # version additionally carries the nested-identifier recursion this class's
      # old copy lacked.

      # Short-form supplement fragment ("sup", "sup1924", "supJan1924",
      # "suprev", " supJun1925-Jun1926"), rendered from the structured
      # component. A present-but-empty component is the bare "sup" marker; a
      # number-less date range gets the leading space the number would have
      # supplied. Shared by base and the per-series to_short_style overrides.
      def supplement_short
        return "" unless supplement

        prefix = supplement.range? && !number ? " " : ""
        rendered = supplement.to_s(:short)
        prefix + (rendered.empty? ? "sup" : rendered)
      end

      # Compute revision from edition component for backward compatibility
      # @return [String, nil] revision string (e.g., "r5") or nil
      def revision
        return @revision if @revision

        # Compute from edition component if available
        if edition&.type && edition.id
          "#{edition.type}#{edition.id}"
        end
      end

      # Backward compatibility: translation method returns translation_component
      # This allows tests to use parsed.translation.language instead of parsed.translation_component.language
      def translation
        translation_component
      end

      # Backward compatibility: language method returns translation_component
      # This allows tests to use parsed.language instead of parsed.translation_component
      def language
        translation_component
      end

      # Override parent render to pass NIST-specific format option through
      # to the renderer. Pubid::Identifier#render only forwards
      # :with_edition; NIST needs :nist_format for multi-format support.
      def render(format: :human, **opts)
        registry = self.class.format_registry
        unless registry
          raise ArgumentError, "No format registry configured on #{self.class}"
        end

        renderer = registry.renderer_for(format)
        unless renderer
          raise ArgumentError, "No renderer registered for format: #{format}"
        end

        renderer.new(self).render(**opts)
      end

      # Generate identifier string in specified format
      # @param format [:full, :long, :abbreviated, :short, :mr] output format
      def to_s(format = nil)
        # Handle both keyword argument (hash) and positional argument (symbol/string)
        format = format[:format] if format.is_a?(Hash)

        # Default to parsed_format if available (preserves input format on round-trip)
        # Falls back to :short format for output (normalization)
        # Explicit format parameter always overrides parsed_format
        render(format: :human,
               nist_format: format || parsed_format&.to_sym || :short)
      end

      # NIST has its own defined MR format (to_mr_style) used by relaton-nist
      # and downstream tooling. The generic Renderers::MrString does not know
      # about NIST series, revisions, supplements, etc., so delegate to the
      # established style for losslessness (issue #142).
      def to_mr_string
        to_mr_style
      end

      # NIST's MR shape is fixed by the pubid standard and stays uppercase
      # (e.g. `NIST.SP.800-53`). The slug, however, must be lowercase to
      # match the cross-flavor convention; project the MR through `downcase`.
      def to_slug
        to_mr_string.downcase
      end

      # Returns weight based on amount of defined attributes
      # Used for ranking identifiers by specificity for conflict resolution
      # @return [Integer] weight score (higher = more specific)
      def weight
        self.class.attributes.keys.inject(0) do |sum, key|
          val = public_send(key)
          val && !val.to_s.empty? ? sum + 1 : sum
        end
      end

      # Merge another document into this one
      # Used for combining document data, preferring more specific values
      # @param document [Base] another NIST document to merge
      # @return [Base] self with merged attributes
      def merge(document)
        return self unless document.is_a?(Pubid::Nist::Identifier)

        attrs = self.class.attributes
        attrs.each_key do |var_name|
          next if var_name == :rendering_style
          next if var_name == :parsed_format

          current_val = public_send(var_name)
          new_val = document.public_send(var_name)
          next unless new_val

          should_merge = case var_name
                         when :publisher, :series, :number
                           true
                         when :edition
                           current_val.nil? || edition_greater?(new_val,
                                                                current_val)
                         when :volume, :part, :version, :revision
                           current_val.nil? || (new_val.to_s.length > current_val.to_s.length)
                         when :supplement, :errata, :index, :insert, :section, :appendix, :translation
                           true
                         when :year, :month, :update, :draft
                           true
                         else
                           false
                         end

          public_send(:"#{var_name}=", new_val) if should_merge
        end

        self
      end

      # Helper to compare edition values numerically
      # @return [Boolean] true if edition1 is greater than edition2
      def edition_greater?(edition1, edition2)
        num1 = extract_edition_number(edition1)
        num2 = extract_edition_number(edition2)
        num1 && num2 && num1 > num2
      end

      # Extract numeric value from edition (r3 -> 3, r5 -> 5, e2 -> 2)
      # @return [Integer, nil] the edition number or nil if not extractable
      def extract_edition_number(edition)
        # Handle both String and Edition component
        edition_str = edition.to_s
        # Match patterns like r3, r5, e2, etc.
        match = edition_str.match(/^[er]?(\d+)$/)
        match ? match[1].to_i : nil
      end

      public

      def to_full_style
        # "National Institute of Standards and Technology Special Publication 800-27, Revision A"
        result = publisher_full_name
        result += " #{series_full_name}" if series
        result += " #{number.value}" if number
        result += parts.map { |p| "-#{p}" }.join if parts&.any?

        # Render volume and issue number in long form: "Vol. 6, No. 12"
        if volume && issue_number
          result += " Vol. #{volume}, #{issue_number.to_s(:long)}"
        elsif volume
          result += " Vol. #{volume}"
        end

        # NEW: Use edition component properly
        result += " #{edition.to_s(:long)}" if edition

        result += ", Revision #{revision.sub(/^r/, '')}" if revision

        # V2: Use version_component
        result += " #{version_component.to_s(:long)}" if version_component

        # V2: Use update_component
        result += " #{update_component.to_s(:long)}" if update_component

        # V2: Use stage
        result += " #{stage.to_s(:long)}" if stage

        # V2: Use translation_component (already includes space)
        result += translation_component.to_s(:long) if translation_component

        result
      end

      def to_abbreviated_style
        # "Natl. Inst. Stand. Technol. Spec. Publ. 800-57 Part 1, Revision 4"
        result = publisher_abbreviated_name
        result += " #{series_abbreviated_name}" if series
        result += " #{number}" if number
        result += " Part #{parts.first}" if parts&.any?

        # NEW: Use edition component properly
        result += " #{edition.to_s(:abbrev)}" if edition

        result += ", Revision #{revision}" if revision

        # V2: Use version_component
        result += " #{version_component.to_s(:abbrev)}" if version_component

        # V2: Use update_component
        result += " #{update_component.to_s(:abbrev)}" if update_component

        # V2: Use stage
        result += " #{stage.to_s(:abbrev)}" if stage

        # V2: Use translation_component
        result += ", #{translation_component.to_s(:abbrev)}" if translation_component

        result
      end

      def to_short_style
        # "SP 800-187" or "NIST SP 800-187" - handle compound series properly
        result = ""

        # Determine effective publisher
        # Only show publisher if it was explicitly parsed (either directly or from series prefix)
        effective_publisher = if publisher && publisher_was_parsed
                                # Publisher was in input (either as separate field or extracted from "NBS CS" series)
                                publisher.to_s
                              else
                                # No publisher in input, don't show default
                                nil
                              end

        # Determine effective series - PREFER series_code if subclass defines it
        # This allows normalization (e.g., LCIRC → LC in LetterCircular)
        effective_series = if series_code
                             series_code
                           elsif series
                             series.to_s
                           end

        # Special handling for compound series that include publisher prefix
        # If series starts with "NBS " (like "NBS CIRC"), use it as-is
        if effective_series&.start_with?("NBS ")
          result += effective_series
        elsif effective_publisher && effective_series
          result += "#{effective_publisher} #{effective_series}"
        elsif effective_series && publisher_was_parsed
          # Only add "NIST" prefix if publisher was explicitly in the input
          result += "NIST #{effective_series}"
        elsif effective_series
          # No publisher in input, just show series without prefix
          result += effective_series
        end

        result += " #{number}" if number
        result += parts.map { |p| "-#{p}" }.join if parts&.any?

        # "NIST Research Library (YYYY)" — oddball identifier with no number;
        # the year appears in parens rather than as a date component.
        result += " (#{year})" if year && !number

        # Append every optional component the parser may have attached
        # (volume, part, edition, version, supplement, update, stage, ...).
        # Shared with the lossy subclasses so they cannot silently drop a
        # distinguishing component and collide with another document.
        result += append_short_components

        result
      end

      # Render the optional component "tail" that follows
      # publisher/series/number in short (human) form. Extracted from
      # #to_short_style so subclasses that build a series-specific prefix can
      # reuse it instead of hand-listing components (and forgetting some).
      #
      # skip_part: true lets a series that renders its part differently
      # (e.g. FIPS uses dash "-1", not "pt1") emit the part itself and skip
      # the generic part rendering here, while still getting volume/edition/
      # supplement/etc.
      def append_short_components(skip_part: false)
        result = ""
        effective_part = skip_part ? nil : part

        # Volume and Part components (v6n1 notation for CSM, pt1 for SP)
        if volume.is_a?(Components::Volume) && effective_part.is_a?(Components::Part)
          # CSM series: v#n# notation
          result += " #{volume}#{effective_part}"
        elsif effective_part.is_a?(Components::Part)
          # SP and other series: use Part.type to determine format
          result += effective_part.to_s
        # Legacy: Render standalone volume (not part of v#n#)
        elsif volume && !issue_number && !effective_part
          vol_str = volume.is_a?(Components::Volume) ? volume.to_s : "v#{volume}"
          result += vol_str
        elsif volume && issue_number
          # Render volume and issue number in short form: "v6n12"
          vol_str = volume.is_a?(Components::Volume) ? volume.to_s : "v#{volume}"
          result += "#{vol_str}n#{issue_number.number}"
        end

        # Use edition component properly (e2, e2021, r5, -3)
        # NO space before edition when number present (per NIST spec)
        # Only add space for bare edition (no number case) or if original_prefix has specific format
        if edition
          if edition.original_prefix && !edition.original_prefix.empty?
            # original_prefix includes the full prefix (e.g., " Rev. " for verbose format)
            result += edition.to_s
          elsif number
            # Number present, NO space: "800-53r5"
            result += edition.to_s
          else
            # Bare edition, add space: " r5"
            result += " #{edition}"
          end
        end

        # Use version_component if available, else use version string.
        # Attach directly (no leading space) to match edition rendering
        # (e.g. "800-53r5"), so version reads "800-45ver2" not
        # "800-45 ver2".
        if version_component
          result += version_component.to_s(:short)
        elsif version
          result += "ver#{version}"
        end

        # Add supplement. NIST/NBS canonical short form is single-p "sup"
        # with the suffix attached directly, no dash (relaton-data-nist
        # uses "sup2", "sup1940", "supA"); date-range keeps its inner dash.
        # Rendered from the structured component; a present-but-empty
        # component is the bare "sup" marker.
        result += supplement_short

        # Add other attributes
        result += errata.to_s if errata
        result += "index" if index
        result += "insert" if insert
        result += "sec#{section}" if section
        result += "app" if appendix

        # Add addendum - render as " Add." suffix
        if addendum || addendum_number
          result += " Add."
        end

        # Use update_component if available, else use update string
        if update_component
          result += update_component.to_s(:short)
        elsif update
          result += "-upd#{update}"
        end

        # Add draft - render as {N}pd if draft_number present
        if draft_number
          result += " #{draft_number}pd"
        elsif draft&.to_s&.include?("draft") && !draft.to_s.include?("Draft)")
          result += "-draft"
        end

        # Add stage component (at end, before translation)
        if stage
          result += " #{stage.to_s(:short)}"
        end

        # Use translation_component if available, else use translation string
        # Note: translation_component.to_s already includes the space prefix
        if translation_component
          result += translation_component.to_s(:short)
        elsif translation
          result += " #{translation}"
        end

        result
      end

      def to_mr_style
        # "NIST.SP.800-116r1.ipd" (machine-readable with dots)
        result = (publisher || "NIST").to_s

        # Determine effective series - PREFER series_code if subclass defines it
        # This allows normalization (e.g., LCIRC → LC in LetterCircular)
        effective_series = if series_code
                             series_code
                           elsif series
                             series.to_s
                           end

        result += ".#{effective_series}" if effective_series
        result += ".#{number}" if number
        result += parts.map { |p| "-#{p}" }.join if parts&.any?

        result += append_mr_components

        result
      end

      # Render the optional component tail for machine-readable (MR) form.
      # Mirrors #append_short_components so the MR output is just as lossless;
      # subclasses that override #to_mr_style reuse this instead of
      # hand-listing components. skip_part: behaves as in the short helper.
      def append_mr_components(skip_part: false)
        result = ""
        effective_part = skip_part ? nil : part

        # Volume / Part components (pt1, v6n1, etc.)
        if volume.is_a?(Components::Volume) && effective_part.is_a?(Components::Part)
          result += "#{volume}#{effective_part}"
        elsif effective_part.is_a?(Components::Part)
          result += effective_part.to_s
        elsif volume && !issue_number && !effective_part
          result += (volume.is_a?(Components::Volume) ? volume.to_s : "v#{volume}")
        elsif volume && issue_number
          vol_str = volume.is_a?(Components::Volume) ? volume.to_s : "v#{volume}"
          result += "#{vol_str}n#{issue_number.number}"
        end

        # Use edition component - NO space before edition in MR format (per NIST spec)
        result += edition.to_s if edition

        # Use version_component
        result += version_component.to_s(:mr) if version_component

        # Supplement (e.g. ".9981sup7") - keep distinct documents distinct
        result += supplement_short

        # Use update_component
        result += update_component.to_s(:mr) if update_component

        # Use stage
        result += ".#{stage.to_s(:mr)}" if stage

        # Add addendum - render as ".Add." suffix in MR format
        if addendum || addendum_number
          result += ".Add."
        end

        # Use translation_component
        result += translation_component.to_s(:mr) if translation_component

        result
      end

      def series_full_name
        {
          "SP" => "Special Publication",
          "FIPS" => "Federal Information Processing Standards",
          "IR" => "Interagency Report",
          "TN" => "Technical Note",
        }[series] || series
      end

      def series_abbreviated_name
        {
          "SP" => "Spec. Publ.",
          "FIPS" => "Fed. Inf. Proc. Stand.",
          "IR" => "Interag. Rep.",
          "TN" => "Tech. Note",
        }[series&.to_s || series_code] || (series&.to_s || series_code)
      end

      def publisher_full_name
        case publisher.to_s
        when "NBS"
          "National Bureau of Standards"
        when "NIST"
          "National Institute of Standards and Technology"
        else
          publisher.to_s
        end
      end

      def publisher_abbreviated_name
        case publisher.to_s
        when "NBS"
          "Natl. Bur. Stand."
        when "NIST"
          "Natl. Inst. Stand. Technol."
        else
          publisher.to_s
        end
      end

      # Default publisher for series without explicit publisher
      # Subclasses can override
      def default_publisher
        "NIST"
      end
    end

  end
end
