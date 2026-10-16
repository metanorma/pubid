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

      # Compact, index-friendly serialization (mirrors the key_value flavors
      # ISO/ITU/ETSI, without a 38-field key_value block). Two transforms,
      # applied symmetrically by to_hash/from_hash so the round-trip stays
      # idempotent:
      #   - flatten the single-value Code components (series, number) to bare
      #     scalars — `value` is the only stored field. NIST's
      #     `Components::Code#part` is a *computed* reader
      #     (`value.split("-").last`), and prefix/subpart/parts are never
      #     assigned on series/number, so the scalar `value` is lossless:
      #     expand recomputes exactly what the object would compute anyway;
      #   - flatten the plain single-value components (volume) to bare scalars
      #     too — `Components::Volume` holds only `value`, so it expands to a
      #     bare { "value" => … } with no part;
      #   - drop the redundant build artifacts, decomposed pieces of the
      #     canonical number that identity/rendering never read.
      COMPACT_FLAT_CODES = %w[series subseries].freeze
      COMPACT_FLAT_VALUES = %w[volume].freeze
      COMPACT_DROP_ATTRS = %w[first_number second_number].freeze

      # Deserialize a (possibly compact) hash: expand the flattened scalars
      # back into Code sub-hashes, then let the shared polymorphic from_hash
      # do the real work. Nested `base` documents are expanded recursively by
      # their own from_hash via apply_mappings, so only this level is touched.
      def self.from_hash(data, options = {})
        super(expand_compact_hash(data), options)
      end

      # Expand a compact hash in place-safe fashion: a scalar series/number
      # becomes { "value" => …, "part" => <last-dash segment> }.
      def self.expand_compact_hash(data)
        return data unless data.is_a?(::Hash)

        out = data.dup
        COMPACT_FLAT_CODES.each do |key|
          out[key] = expand_code(out[key]) if out[key].is_a?(::String)
        end
        COMPACT_FLAT_VALUES.each do |key|
          out[key] = { "value" => out[key] } if out[key].is_a?(::String)
        end
        # Legacy index rows (the pre-flattening component era) carry the
        # number as a {"value" => …} Hash; the attribute is a plain
        # string now, so the Hash collapses to its scalar before the
        # assignment dumps it (pubid#540).
        if out["number"].is_a?(::Hash) && out["number"].key?("value")
          out["number"] = out["number"]["value"]
        end
        out
      end

      # A flattened Code scalar -> { "value" => …, "part" => <last-dash seg> }.
      def self.expand_code(value)
        code = { "value" => value }
        code["part"] = value.split("-").last if value.include?("-")
        code
      end

      # Serialize, then apply the compact transforms (recursing into a nested
      # `base`, which lutaml serialized via its own transform — bypassing this
      # override — so it is not compacted otherwise).
      def to_hash(*args)
        hash = super
        compact_hash!(hash) if hash.is_a?(::Hash)
        hash
      end

      def compact_hash!(hash)
        COMPACT_DROP_ATTRS.each { |key| hash.delete(key) }
        (COMPACT_FLAT_CODES + COMPACT_FLAT_VALUES).each do |key|
          value = hash[key]
          next unless value.is_a?(::Hash) && value.key?("value")

          hash[key] = value["value"]
        end
        compact_hash!(hash["base"]) if hash["base"].is_a?(::Hash)
        hash
      end
      private :compact_hash!

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
      # Plain :string. NIST never populated the Code beyond `value`: `subpart`
      # is set nowhere, and `part` was a reader splitting `value` on "-" that
      # no library code called. `series`, `subseries`, `first_number`,
      # `second_number` and `parts` keep the component.
      attribute :number, :string
      # NIST never uses `subpart`; declare it so the inherited Components::Code
      # does not disagree with this class (the determinism landmine).
      attribute :subpart, :string

      # V2 COMPONENTS (Lutaml::Model objects) - PROPER SEPARATION
      # `edition` (Components::Edition: type + id + additional_text) is the
      # single source of truth for edition/revision. The former
      # `edition_component` (a byte-identical duplicate) and the `revision`
      # string (always "#{edition.type}#{edition.id}") were unfinished V1->V2
      # migration aliases; both removed. `#revision` survives as a derived
      # reader below.
      attribute :edition, Components::Edition # Edition (type + id): e2, e2021, r5, -3
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
        # This override calls `super()` with no attributes and assigns through
        # setters instead, so it bypasses the base constructor's coercion and
        # unknown-key check. Apply them here to keep the cross-flavor contract.
        attributes = self.class.normalize_init_attributes(attributes)
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
      #   - first_number/second_number: decomposed parts of the canonical
      #     :number, retained from the parse for building
      #   - parsed_format: records the input format for round-trip rendering
      #   - subseries: derived from series+number (which SP subseries the
      #     document belongs to); populated by the Builder for known SP
      #     subseries codes. Ignored in equality so a manually-built id
      #     without subseries set still equals a parsed one.
      EQUALITY_IGNORED_ATTRS = %i[
        first_number second_number parsed_format subseries
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

      # A subset match skips the same attributes: `to_hash` drops the build
      # artifacts, so an index row rebuilt by `from_hash` never has them.
      def self.subset_ignored_attributes
        EQUALITY_IGNORED_ATTRS
      end

      # `edition` is the primary edition/revision carrier and is already in
      # the default %i[date year edition version] list. `update`/
      # `update_component` (Components::Update: number+year+month) is a
      # SEPARATE, currently-live discriminator the default list misses — the
      # Letter Circular / Circular "rJun1992"-style revision parses into it,
      # not into `edition` (see Builder#build_dated_identifier), so e.g.
      # "NBS LC 800 rJun1992" and "NBS LC 800 rJul1995" failed to collapse
      # under #to_all_parts/#=== before this override. (`edition_year` and
      # `revision_year`/`revision_month` are NOT added here: the builder
      # always sets `edition_year` alongside the real `edition` component
      # (never alone), and `revision_year`/`revision_month` are transient —
      # converted into `update`/`update_component` and cleared to nil before
      # the object is returned — so neither carries live information outside
      # what `edition`/`update` already do.)
      def self.all_parts_edition_keys
        super + %i[update update_component]
      end

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

      # Derived, read-only revision string ("r5", "e1979", "-3") for backward
      # compatibility. `edition` is the single stored representation; this is
      # never persisted, compared, or merged — just a convenience view of it.
      # @return [String, nil] revision string (e.g., "r5") or nil
      def revision
        "#{edition.type}#{edition.id}" if edition&.type && edition.id
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
        annotated = format.is_a?(Hash) ? format[:annotated] : nil
        format = format[:format] if format.is_a?(Hash)

        # Default to parsed_format if available (preserves input format on round-trip)
        # Falls back to :short format for output (normalization)
        # Explicit format parameter always overrides parsed_format
        rendered = render(format: :human,
                          nist_format: format || parsed_format&.to_sym || :short)

        # NIST's `to_s` takes a POSITIONAL format and its `render` override
        # builds no rendering context, so neither the flag nor the context
        # reaches the shared hook. Apply the annotation fallback here.
        annotate_plain_render(rendered, annotated: annotated)
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
          next sum if EQUALITY_IGNORED_ATTRS.include?(key)

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
                         when :volume, :part, :version
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

      def to_full_style
        # "National Institute of Standards and Technology Special
        # Publication 1000 Part 1 Supplement 3 Section 2 Index Update 5
        # (2021)(en)" - the edition renders its own long form ("Revision
        # 5" / "(2021)"), never the derived revision view alongside it
        result = publisher_full_name
        result += " #{series_full_name}" if series
        result += " #{number}" if number
        result += parts.map { |p| "-#{p}" }.join if parts&.any?

        # The 1.x corpus order: stage, volume, part, revision, version,
        # supplement, section, update; an edition date trails as the
        # parenthesised date before the translation
        result += " #{stage.to_s(:long)}" if stage

        # Volume and issue number in long form: "Volume 6, No. 12" - the
        # component's own v-notation must not leak into the worded form
        if volume && issue_number
          result += " Volume #{volume.value}, #{issue_number.to_s(:long)}"
        elsif volume
          result += " Volume #{volume.value}"
        end

        result += " Part #{part.value}" if part
        result += " #{edition.to_s(:long)}" if edition && !edition_year?
        # A revision riding on a date edition composes at the revision
        # slot ("... Part 2, Revision 3 ... (2001)")
        if edition&.additional_text.to_s =~ /\Ar(\d+)\z/
          result += " Revision #{Regexp.last_match[1]}"
        end
        result += " #{version_component.to_s(:long)}" if version_component
        result += " #{supplement.to_s(:long)}" if supplement
        result += " Section #{section}" if section
        result += " Index" if index
        result += " #{update_component.to_s(:long)}" if update_component

        result += " #{edition.to_s(:long)}" if edition && edition_year?

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

        # The edition renders its own form ("Revision 5" / "(2021)");
        # the derived revision view never renders alongside it
        result += " #{edition.to_s(:long)}" if edition

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
          # the volume keeps its leading space before the part
          # ("535 v1pt1"), the corpus form (testsuite 10491/10492)
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
        elsif issue_number
          # A standalone issue renders its own short form (pubid#497 -
          # the metanorma-nist port passes the index here; n4 must not
          # silently drop).
          result += issue_number.to_s(:short)
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
        result += "insert" if insert
        # The 1.x order is section before index ("sup3sec2indx"); the index
        # spelling is the abbreviated indx (pubid#497) — the full "index"
        # input spelling canonicalizes onto it.
        result += "sec#{section}" if section
        result += "indx" if index
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
        elsif issue_number
          # A standalone issue renders its own short form (pubid#497)
          result += issue_number.to_s(:mr)
        end

        # With a number, the edition glues to it per the NIST spec
        # ("800-53r5"); series-only editions take a dot separator
        # ("NBS.CIRC.e2" — the attested raw spelling; testsuite#5 C4/C5).
        result += if edition
                    number ? edition.to_s : ".#{edition}"
                  else
                    ""
                  end

        # Use version_component
        result += version_component.to_s(:mr) if version_component

        # Supplement (e.g. ".9981sup7") - keep distinct documents distinct;
        # a series-only supplement ("NBS.CIRC.sup") takes the dot itself.
        result += if supplement
                    number ? supplement_short : ".#{supplement_short}"
                  else
                    ""
                  end

        # Use update_component
        result += update_component.to_s(:mr) if update_component

        # Use stage
        result += ".#{stage.to_s(:mr)}" if stage

        # Add addendum - render as ".Add." suffix in MR format
        if addendum || addendum_number
          result += ".Add."
        end

        # Section and index travel with the identifier in MR form too
        # (pubid#497 - sec<N> / indx must not drop)
        result += ".sec#{section}" if section
        result += ".indx" if index

        # Use translation_component
        result += translation_component.to_s(:mr) if translation_component

        result
      end

      # An e-type edition whose id is a date (year or full date)
      # composes as the trailing parenthesised date
      def edition_year?
        edition&.type == "e" && edition.id.to_s =~ /\A\d{4}(\d{2}(\d{2})?)?\z/
      end

      def series_full_name
        {
          "SP" => "Special Publication",
          "FIPS" => "Federal Information Processing Standards Publication",
          "IR" => "Interagency Report",
          "TN" => "Technical Note",
          "CSWP" => "Cybersecurity White Papers",
        }[series.to_s] || series.to_s
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
