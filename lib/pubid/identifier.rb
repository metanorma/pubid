# frozen_string_literal: true

module Pubid
  class Identifier < Lutaml::Model::Serializable
    class << self
      def format_registry
        @format_registry || superclass&.format_registry
      end

      attr_writer :format_registry

      # Polymorphic deserialization shared by every flavor base. lutaml's
      # `key_value` polymorphic_map reads `_type` only to VALIDATE; it does not
      # re-instantiate the concrete subclass. So a base-class `from_hash` would
      # return a bare base object and drop subtype-specific attributes (e.g. a
      # supplement's base). Route by `_type` to the concrete class
      # named in `polymorphic_type_map`, then let its inherited from_hash (this
      # method again, where klass == self) fall through to lutaml's real work.
      #
      # This generalizes the per-flavor `*_TYPE_MAP` dispatch that ISO, JIS,
      # IEC, CCSDS and IHO each hand-rolled — one implementation, inherited by
      # every flavor base. Cross-flavor dispatch (a nested adopted identifier
      # whose _type belongs to a different flavor) is delegated to
      # {TypeResolver}, which knows about every registered flavor.
      def from_hash(data, options = {})
        klass = concrete_class_for(data)
        return klass.from_hash(data, options) if klass && klass != self
        super
      end

      # lutaml's nested polymorphic cast (Attribute#cast → apply_mappings)
      # bypasses {from_hash}, so cross-flavor dispatch wouldn't fire for a
      # nested attribute that carries another flavor's _type. Intercept
      # apply_mappings and route to {from_hash} so the concrete class's own
      # mappings (with their flavor-specific custom cast methods, e.g. ISO's
      # number_from_kv) drive deserialization.
      def apply_mappings(doc, format, options = {})
        return super unless hash_with_type?(doc, format)

        klass = concrete_class_for(doc)
        return super unless klass && klass != self

        klass.from_hash(doc, options)
      end

      # Resolve a polymorphic _type to the concrete class that owns it:
      # this flavor's own map first, then any registered flavor's map via
      # {TypeResolver}. Returns nil for blank or unknown types.
      def concrete_class_for(data)
        type = data && (data["_type"] || data[:_type])
        return nil unless type

        polymorphic_type_map[type] || ::Pubid::TypeResolver.resolve(type)
      end

      # Map of polymorphic_name ("pubid:iso:corrigendum") => concrete class for
      # the flavor this base belongs to. Built once by scanning the flavor's
      # `Identifiers` namespace for Pubid::Identifier descendants and unioning
      # the flavor's `identifier_types` registry (which may register classes
      # living outside that namespace, e.g. ISO's BundledIdentifier). Memoized
      # per class. Public so {TypeResolver} can read another flavor's map for
      # cross-flavor polymorphic dispatch.
      def polymorphic_type_map
        @polymorphic_type_map ||=
          identifier_registry_classes.each_with_object({}) do |klass, map|
            poly = klass.polymorphic_name
            map[poly] ||= klass if poly
          end
      end

      private

      def hash_with_type?(doc, format)
        format == :hash && doc.is_a?(Hash) && (doc["_type"] || doc[:_type])
      end

      private

      # The flavor module namespacing this base, e.g. Pubid::Iso for
      # Pubid::Iso::Identifier (and for the inherited Pubid::Iso::Identifiers::
      # Corrigendum). Always the first two name components, so it is stable
      # whether `self` is the base or a concrete subclass.
      def flavor_module
        @flavor_module ||= Object.const_get(name.split("::")[0, 2].join("::"))
      end

      def identifiers_namespace
        @identifiers_namespace ||= flavor_module.const_get(:Identifiers)
      end

      def identifier_registry_classes
        (scanned_identifier_classes +
          registered_identifier_classes +
          additional_identifier_classes).uniq
      end

      # Concrete identifier classes found directly in the flavor's `Identifiers`
      # namespace. Empty for the abstract root (no flavor) or a flavor without
      # that namespace. Only this namespace is scanned (never the flavor top
      # level), to avoid force-autoloading unrelated flavor constants.
      def scanned_identifier_classes
        return [] unless flavor_identifiers_namespace?

        identifiers_namespace.constants.filter_map do |const|
          klass = identifiers_namespace.const_get(const)
          klass if klass.is_a?(Class) && klass < ::Pubid::Identifier
        rescue NameError
          nil
        end
      end

      # Classes the flavor explicitly registers via `identifier_types`, if any.
      def registered_identifier_classes
        return [] unless flavor_module.respond_to?(:identifier_types)

        Array(flavor_module.identifier_types)
      end

      # Hook for identifier classes that carry a polymorphic `_type` but live
      # OUTSIDE the flavor's `Identifiers` namespace (e.g. Pubid::Iso::
      # BundledIdentifier, Pubid::Iec::SingleIdentifier). Flavors with such
      # classes override this; the default is none. Replaces the hand-listing
      # of these in the old static `*_TYPE_MAP`s.
      def additional_identifier_classes
        []
      end

      def flavor_identifiers_namespace?
        flavor_module.const_defined?(:Identifiers)
      rescue NameError
        false
      end
    end

    attribute :_type, :string, polymorphic_class: true
    attribute :number, Components::Code
    attribute :part, Components::Code
    attribute :subpart, Components::Code
    attribute :stage_iteration, Components::Iteration
    attribute :date, Components::Date
    attribute :edition, Components::Edition
    attribute :languages, Components::Language, collection: true
    attribute :publisher, Components::Publisher
    attribute :copublishers, Components::Publisher, collection: true
    attribute :type, Components::Type
    attribute :stage, Components::Stage
    attribute :locality, Components::Locality
    attribute :typed_stage, Components::TypedStage
    attribute :all_parts, Lutaml::Model::Type::Boolean, default: false
    # base is declared by supplement subclasses with proper type
    def base
      nil
    end

    # The underlying standard, with amendment / corrigendum / Expert-commentary
    # / Flex-version wrappers peeled recursively. Wrapper subclasses override
    # this; a plain identifier is its own base document.
    def base_document
      self
    end

    # @return [String, nil] publication year from the date component
    def year
      date&.year&.to_s
    end

    # Canonicalize the serialized hash so it never carries a defaulted attribute
    # still at its default (or empty) value. This makes to_hash a pure function
    # of the identifier's values, independent of how the object was built.
    #
    # Motivation: lutaml materializes each attribute's default as an explicit
    # assignment during deserialization (flipping using_default? to false), so a
    # naive from_hash(x).to_hash re-emits defaults that parse(x).to_hash omits —
    # breaking the exact-equality round-trip relaton-index relies on
    # (from_hash(raw).to_hash == raw). pubid never consults lutaml's unset
    # tracking and defines no render_default: true, so a defaulted attribute at
    # its default/empty value carries no meaning and does not belong in the
    # canonical hash. Dropping it here (rather than repairing from_hash) fixes
    # the round-trip through every construction path — parse, from_hash, manual.
    def to_hash(*args)
      hash = super
      canonicalize_hash(self, hash) if hash.is_a?(::Hash)
      hash
    end

    # Recursively drop attributes holding only their default (or empty) value
    # from +hash+, the serialization of +model+. Recurses into nested component
    # / identifier values because lutaml serializes those via its own transform
    # — bypassing their public to_hash — so a nested defaulted attribute (e.g.
    # Components::Supplement#has_revision) would otherwise leak into the parent
    # hash and break the idempotent round-trip.
    def canonicalize_hash(model, hash)
      register = model.lutaml_register
      model.class.attributes(register).each do |name, attr|
        canonicalize_attr(model, hash, name, attr) unless name == :_type
      end
    end

    # Canonicalize a single attribute against its serialized value in +hash+:
    # drop it when it holds only its default/empty value, else recurse into it.
    def canonicalize_attr(model, hash, name, attr)
      key = hash.key?(name.to_s) ? name.to_s : name
      return unless hash.key?(key)

      value = model.public_send(name)
      if default_valued?(value, attr, model)
        hash.delete(key)
      else
        canonicalize_nested(value, hash[key])
      end
    end

    # True when +value+ is +attr+'s default (or empty), so it can be dropped.
    def default_valued?(value, attr, model)
      register = model.lutaml_register
      attr.default_set?(register, model) &&
        (Lutaml::Model::Utils.empty?(value) ||
          value == attr.default(register, model))
    end

    # Recurse into a nested component / identifier (or a collection of them) so
    # its own defaulted attributes are canonicalized against its sub-hash.
    def canonicalize_nested(value, sub)
      if value.is_a?(Lutaml::Model::Serialize)
        canonicalize_hash(value, sub) if sub.is_a?(::Hash)
      elsif value.is_a?(::Array)
        canonicalize_collection(value, sub)
      end
    end

    # Canonicalize each element of a collection against its serialized sub-hash.
    # Only zip when object and serialized sizes match, so a (never-observed)
    # length mismatch can't pair an element with the wrong sub-hash — worst case
    # it leaves that collection untouched.
    def canonicalize_collection(models, subs)
      return unless subs.is_a?(::Array) && models.size == subs.size

      models.each_with_index do |model, i|
        canonicalize_nested(model, subs[i])
      end
    end
    private :canonicalize_hash, :canonicalize_attr, :default_valued?,
            :canonicalize_nested, :canonicalize_collection

    def initialize(attrs = {}, options = {})
      attrs = attrs.dup
      attrs[:_type] ||= self.class.polymorphic_name
      super
    end

    def self.polymorphic_name
      return nil unless name

      parts = name.split("::")
      flavor = parts[1]&.downcase
      type_kebab = parts.last
        .gsub(/([A-Z]+)([A-Z][a-z])/, '\1-\2')
        .gsub(/([a-z\d])([A-Z])/, '\1-\2')
        .downcase
      "pubid:#{flavor}:#{type_kebab}"
    end

    def root
      return base.root if base

      self
    end

    # Unified render — delegates to format registry
    def render(format: :human, **opts)
      registry = self.class.format_registry
      unless registry
        raise ArgumentError, "No format registry configured on #{self.class}"
      end

      renderer = registry.renderer_for(format)
      unless renderer
        raise ArgumentError, "No renderer registered for format: #{format}"
      end

      # `:trademark` is a render-time flag consumed by the renderer, not the
      # rendering context — and some flavors override build_rendering_context
      # with a strict signature, so strip it here.
      ctx_opts = opts.except(:trademark)
      context = build_rendering_context(renderer, format:, **ctx_opts)
      render_opts = opts.slice(:with_edition, :trademark)
      renderer.new(self).render(context:, **render_opts)
    end

    def to_s(**opts)
      render(format: :human, **opts)
    end

    def to_mr_string
      render(format: :mr_string)
    end

    # Filesystem-/URL-safe slug derived from the MR string. Defaults to
    # `to_mr_string` because every flavor except NIST already emits an
    # all-lowercase, filename-safe MR (only `[a-z0-9.-]` characters, plus
    # `_` as the supplement separator and `-` as the copublisher separator).
    # Flavors whose MR is not slug-safe (notably NIST, whose MR format is
    # fixed by the pubid standard) override this to project the MR into a
    # slug-safe form.
    def to_slug
      to_mr_string
    end

    # MR string template methods — flavors override as needed.
    #
    # The MR format is a lossless, dot-separated, all-lowercase, filename-safe
    # slug mirroring `to_s`'s structure:
    #
    #   {publisher}[-{copublisher}…][.{type}].{number}[-{part}[-{subpart}…]]
    #   [.{year}[-{month}[-{day}]]|’--’}][.{edition}][.{language}-{language}…]
    #   [.all-parts][_supplements…]
    #
    # Supplements append `_{type}.{number}.{year}` recursively, so a chained
    # supplement like `…/Amd 3:2016/Cor 1:2017` round-trips as
    # `…_amd.3.2016_cor.1.2017`. Copublishers join with `-`
    # (`iso-iec.17031-1.2020`) so the slug never contains a path separator.
    # Distinct identifiers never collide on `to_mr_string` (issue #142).
    def mr_publisher
      publisher&.to_s&.downcase&.tr("/", "-")
    end

    def mr_type
      return nil unless typed_stage

      code = typed_stage.type_code
      return nil if code.nil? || code.empty? || code.to_s == "is"

      code.to_s.downcase
    end

    def mr_number_with_part
      num = mr_number
      return nil unless num

      segments = [num]
      segments << mr_part if part
      segments << mr_subpart if subpart
      segments.compact.join("-").downcase
    end

    # Join MR segments and return nil rather than "" when nothing survives.
    #
    # Renderers::MrString does `parts.compact.join(".")`, and `compact` removes
    # nil but NOT an empty string — so a hook that returns "" contributes a
    # blank segment and the slug gains a double dot. The base
    # #mr_number_with_part guards this with its own `return nil unless num`;
    # flavor overrides that append their own marker to `super` need the same
    # guard, and this is it.
    def mr_join(*segments)
      joined = segments.compact.reject { |s| s.to_s.empty? }.join("-")
      joined.empty? ? nil : joined
    end

    def mr_number
      number&.to_s&.downcase
    end

    def mr_part
      part&.to_s&.downcase
    end

    def mr_subpart
      subpart&.to_s&.downcase
    end

    def mr_year
      return nil unless date
      return "--" if date.respond_to?(:undated?) && date.undated?
      return nil unless date.year

      result = date.year.to_s
      result += "-#{date.month}" if date.respond_to?(:month) && date.month
      result += "-#{date.day}" if date.respond_to?(:day) && date.day
      result
    end

    def mr_edition
      return nil unless edition&.number

      "ed#{edition.number}"
    end

    def mr_languages
      return nil unless languages&.any?

      # Hyphen-joined, no parens — parens are shell-/URL-unsafe.
      languages.map { |l| l.code.to_s.downcase }.join("-")
    end

    def mr_all_parts
      return nil unless all_parts

      "all-parts"
    end

    # Hook: supplement / wrapper subclasses return the `{type}.{number}.{year}`
    # suffix that distinguishes them from their base. `nil` for non-supplements.
    # The base MrString renderer recurses into `base` whenever this returns
    # a non-nil value, so chained supplements (Cor → Amd → IS) render fully.
    # The suffix is appended with `_` (not `/`) so the MR stays filename-safe.
    def mr_supplement_suffix
      nil
    end

    # URN template methods — flavors override as needed
    def urn_type_code
      nil
    end

    def urn_supplement_type
      nil
    end

    # Supplement rendering hook — flavors override for supplement-specific rendering
    def to_supplement_s(**opts)
      to_s(**opts)
    end

    # Default URN generation — resolves flavor's UrnGenerator class
    def to_urn
      resolve_urn_generator.new(self).generate
    end

    def resolve_urn_generator
      flavor = self.class.name.split("::")[1]
      Object.const_get("Pubid::#{flavor}::UrnGenerator")
    rescue NameError
      Pubid::UrnGenerator::Base
    end

    # Excluded attributes are nilled; every other value is passed through
    # #exclude_from_nested so the exclusion also propagates into nested
    # identifiers — wrapper types (adopted standards, consolidated amendments,
    # expert-commentary wrappers) delegate their date to an inner identifier
    # rather than storing it in their own attribute.
    def exclude(*args)
      # :amendment / :supplement are structural, not attributes — they reduce
      # a supplemented identifier to the standard it wraps (#drop_supplements).
      supplement_keys = args & %i[amendment supplement]
      unless supplement_keys.empty?
        return drop_supplements.exclude(*(args - supplement_keys))
      end

      excluded_args = args.dup
      # Map :year to :date (year-in-date flavors), but ALSO keep :year so a
      # flavor that models the edition as a plain `year` attribute (e.g. GOST)
      # has it excluded too. The loop below nils whichever name the flavor has.
      excluded_args << :date if excluded_args.include?(:year)

      attrs = self.class.attributes.each_with_object({}) do |(name, _), h|
        value = excluded_args.include?(name) ? nil : public_send(name)
        h[name] = exclude_from_nested(value, args)
      end
      # Splat the rebuilt attributes as keywords. Flavors whose identifier
      # #initialize is keyword-only (ITU, IEEE, …) would raise ArgumentError on
      # a positional hash under Ruby 3 kwarg separation; the base
      # initialize(attrs = {}, options = {}) still accepts **attrs because Ruby
      # passes keywords to a no-keyword method as a trailing positional Hash.
      self.class.new(**attrs)
    end

    # The standard this identifier supplements, dropping its own supplement
    # layer (one level). Overridden by ConsolidatedIdentifier / Amendment /
    # Corrigendum; a non-supplement identifier supplements nothing, so it is
    # returned unchanged.
    def drop_supplements
      self
    end

    # Fuzz-level equality: two identifiers match when they are equal after
    # excluding the given aspects. `ignore` accepts the same symbols as #exclude
    # (e.g. :date, :edition, :amendment). This is the primitive relaton uses to
    # match a reference against catalogue hits at varying strictness.
    def matches?(other, ignore: [])
      return false unless other.is_a?(::Pubid::Identifier)

      exclude(*ignore) == other.exclude(*ignore)
    end

    def new_edition_of?(other)
      unless publisher == other.publisher
        raise ArgumentError,
              "Cannot compare edition: different publisher"
      end
      unless number == other.number
        raise ArgumentError,
              "Cannot compare edition: different number"
      end
      unless part == other.part
        raise ArgumentError,
              "Cannot compare edition: different part"
      end

      unless date && other.date
        raise ArgumentError,
              "Cannot compare identifier without date/year"
      end

      return date.year > other.date.year if date.year != other.date.year

      if edition && other.edition
        return edition.number > other.edition.number
      end

      false
    end

    # --- Relational algebra (pubid/pubid#247) ---
    # Each predicate returns true / false. Predicates that don't apply to
    # this identifier type (e.g. supplement checks on a non-wrapper) return
    # false rather than raising. This makes them safe for chain-of-checks
    # patterns like `id.related_to?(other)`.

    # Self is a supplement (amendment / corrigendum / errata / supplement)
    # of +other+. Self must be a wrapper (has a +base+ attribute) whose
    # inner base equals +other+.
    def supplement_of?(other)
      return false unless other.is_a?(::Pubid::Identifier)
      return false unless self.class.attributes.key?(:base)

      base == other
    end

    # Inverse of #supplement_of? — self is the base document and +other+
    # is a supplement attached to it.
    def has_supplement?(other)
      other.is_a?(::Pubid::Identifier) && other.supplement_of?(self)
    end

    # Self and +other+ refer to the same document but differ only in the
    # trailing date / year — the "dated vs undated" reference pattern.
    def dated_version_of?(other)
      return false unless other.is_a?(::Pubid::Identifier)

      matches?(other, ignore: [:date, :year]) && self != other
    end

    # Self and +other+ have the same publisher + number but differ in
    # part, subpart, or edition. This is the "sibling documents" pattern:
    # same base standard, different sub-component.
    def sibling_of?(other)
      return false unless other.is_a?(::Pubid::Identifier)

      publisher == other.publisher &&
        number == other.number &&
        self != other
    end

    # Self is an all-parts collection that covers +other+.
    def includes?(other)
      return false unless other.is_a?(::Pubid::Identifier)
      return false unless all_parts

      root == other.root
    end

    # Self is a draft version of +other+ (the published identifier).
    # IEEE uses draft_status + draft; ISO/IEC use typed_stage.
    def draft_of?(other)
      return false unless other.is_a?(::Pubid::Identifier)

      root == other.root &&
        self != other &&
        matches?(other, ignore: [:date, :year, :stage, :typed_stage])
    end

    # Self and +other+ have the same publisher + number + part but differ
    # in edition / revision marker.
    def edition_of?(other)
      return false unless other.is_a?(::Pubid::Identifier)

      publisher == other.publisher &&
        number == other.number &&
        part == other.part &&
        self != other
    end

    # Any relational predicate holds.
    def related_to?(other)
      %i[supplement_of? has_supplement? dated_version_of? edition_of?
         sibling_of? includes? draft_of?].any? do |m|
        public_send(m, other)
      end
    end

    def hash
      @hash ||= compute_hash
    end

    def eql?(other)
      return false unless other.is_a?(self.class)

      hash == other.hash && self == other
    end

    private

    # Propagate an #exclude into a nested attribute value: recurse when it is
    # (or contains) another identifier, otherwise return it unchanged.
    # Components and scalars are copied as-is. Passes the original args so
    # nested identifiers re-apply the same :year->:date mapping themselves.
    def exclude_from_nested(value, args)
      case value
      when ::Pubid::Identifier
        value.exclude(*args)
      when Array
        value.map { |item| exclude_from_nested(item, args) }
      else
        value
      end
    end

    def build_rendering_context(_renderer, format:, with_edition: false,
                                lang: :en, lang_single: false,
                                stage_format_long: nil, with_date: nil,
                                annotated: false)
      if format == :mr_string
        nil
      else
        Rendering::RenderingContext.new(
          with_language_code: lang_single ? :single : :none,
          stage_format_long: stage_format_long || false,
          with_date: with_date.nil? || with_date,
          annotated: annotated,
        )
      end
    end

    def compute_hash
      attrs = [
        publisher,
        number,
        part,
        subpart,
        date,
        type,
        stage,
      ]
      attrs.compact.map(&:hash).hash
    end
  end
end
