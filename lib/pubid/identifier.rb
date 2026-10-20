# frozen_string_literal: true

module Pubid
  class Identifier < Lutaml::Model::Serializable
    # `reference === candidate`: a subset match (see Pubid::SubsetMatch).
    include SubsetMatch

    # Components that serialize as a bare scalar when they carry only their
    # single significant field: attribute name => the key the scalar is emitted
    # under. `date` is RENAMED to `year`, matching the flat shape ISO and IEC
    # already emit through their own converters.
    #
    # `stage_iteration` is a Components::Iteration, which holds one `:string`
    # field and whose `to_s`/`render` return it — degenerate by construction.
    #
    # Every flavor INHERITS the attribute, so the reach of this entry is not the
    # set of flavors that map the key but the set that ever POPULATES it. That
    # was measured over every flavor's whole pass-fixture corpus (~99k ids):
    # only ISO does, 91 times, and ISO emits the bare scalar through its own
    # converter — which the inflation guard below defers to — so its serialized
    # shape is unchanged (verified byte-identical over all 7,573 ISO ids). IEC
    # is the flavor this entry is for; it dropped its converter pair for a
    # plain map. For every other flavor the `hash.key?` guard never fires.
    FLAT_SCALAR_COMPONENTS = {
      edition: "edition",
      date: "year",
      stage_iteration: "stage_iteration",
    }.freeze

    # The one field each of those components degenerates to.
    FLAT_SCALAR_FIELDS = {
      edition: :number,
      date: :year,
      stage_iteration: :number,
    }.freeze

    # The one field each degenerate component collapses to, keyed by the
    # component CLASS rather than the attribute name — so a collection
    # attribute (`languages`, `copublishers`) and a flavor subclass
    # (Pubid::Iec::Components::Publisher) are both covered by one entry.
    #
    # `Components::Code` is deliberately absent. A String left in `number`
    # renders and serializes correctly today, and coercing it would turn
    # `to_hash` from {"number" => "1000"} into {"number" => {"value" => "1000"}}
    # on the five flavors that still declare a Code (iso, nist, csa, sae,
    # ccsds) — an index wire-format change, and one the `number` retype tranches
    # sequence to land last. The two entries here are the components that RAISE
    # when a String reaches them, so coercing them can only repair.
    #
    # IEC used to be a sixth, and its removal shows the cost of the split the
    # other way round: because `parse` gave a Code and `new` left a String, a
    # hand-built IEC identifier was never `==` the parsed one. Retyping the
    # attribute — not coercing the value — is what reconciles the two paths.
    DEGENERATE_COMPONENT_FIELDS = {
      Components::Language => :code,
      Components::Publisher => :body,
    }.freeze

    # Keys lutaml reads out of the attribute hash itself
    # (Serializable#extract_register_id), so they are reserved rather than
    # unknown and must survive the unknown-key check.
    RESERVED_INIT_KEYS = %i[lutaml_register].freeze

    # Scalar aliases accepted by the constructor for a component-valued
    # attribute: alias => [target attribute, the component field it fills].
    # `year` is the one the issue names — it is a READER over `date`, never an
    # attribute, on every date-based flavor, so `new(number: "1000", year: 2023)`
    # used to build an identifier with no year and say nothing.
    SCALAR_ATTRIBUTE_ALIASES = {
      year: [:date, :year],
      month: [:date, :month],
      day: [:date, :day],
    }.freeze


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

        # A row written before "all parts" became a class carries the old
        # `all_parts: true` key on the document itself. Read it, and wrap.
        legacy_all_parts = data.is_a?(::Hash) &&
          (data["all_parts"] || data[:all_parts])

        id = super(inflate_scalar_components(data), options)
        legacy_all_parts ? id.to_all_parts : id
      end

      # Accept the flat scalar form that {#to_hash} now emits, and the nested
      # form every stored row was written with. lutaml casts a Hash into a
      # component but passes a String straight through (Attribute#cast_element),
      # so the flat form has to be re-inflated here or it would be assigned raw.
      #
      # Reading BOTH shapes is what keeps published relaton-data indexes
      # deserializing across this change.
      def inflate_scalar_components(data)
        return data unless data.is_a?(::Hash)

        flat_scalar_components.each_with_object(data.dup) do |(attr, key), acc|
          inflate_scalar_component(acc, attr, key)
        end
      end

      # The flat-scalar table of this class: FLAT_SCALAR_COMPONENTS, plus the
      # entries a flavor adds for its own classes. CEN/CENELEC adds
      # `publisher` and `copublishers`; a table shared by every flavor would
      # change the wire format of flavors with a published index (IEEE).
      def flat_scalar_components
        FLAT_SCALAR_COMPONENTS
      end

      # The one field each entry of #flat_scalar_components degenerates to.
      def flat_scalar_fields
        FLAT_SCALAR_FIELDS
      end

      # Hook: rewrite +hash+, the canonical serialization of +model+ (an
      # instance of this class), into a shorter flavor-specific form. The
      # canonicalizer calls it for every identifier, nested ones included, so
      # it also reaches a `base` or an adopted document. A class that
      # overrides it must also override #inflate_scalar_components to read the
      # short form back. The default changes nothing.
      def compact_hash(_model, _hash); end

      # @api private
      def inflate_scalar_component(data, attr_name, flat_key)
        return unless component_attribute?(attr_name)
        # A flavor with its OWN converter for the flat key (IEC's
        # year_from_kv) already knows how to read it, and inflating would fight
        # it. A plain `map "edition", to: :edition` is not such a converter —
        # it hands the value to lutaml, which cannot cast a String into a
        # component — so that one still needs inflating.
        return if converted_hash_keys.include?(flat_key)
        # Only when the flat key RENAMES the attribute (`date` -> `year`) can
        # it collide with a different attribute. ~20 flavors model the edition
        # as a real `year` attribute of their own (ASHRAE, ASME, CIE, CSA, JIS,
        # OGC, IEEE …), and folding that into a `date` component silently drops
        # the year on every round trip — the same collision
        # `fold_scalar_aliases` guards against on the constructor path.
        # `edition` keeps its own name, so it is never a collision.
        return if flat_key != attr_name.name && declared_attribute?(flat_key)

        key = data.key?(flat_key) ? flat_key : flat_key.to_sym
        value = data[key]
        return if value.nil? || value.is_a?(::Hash)

        field = flat_scalar_fields.fetch(attr_name).name
        if value.is_a?(::Array)
          # A collection of components (`copublishers`) flattens to a list of
          # scalars; anything else in a list is not the flat form.
          return unless collection_attribute?(attr_name)
          return unless value.all? { |v| scalar_value?(v) }

          data.delete(key)
          data[attr_name.name] = value.map { |v| { field => v.to_s } }
          return
        end

        data.delete(key)
        data[attr_name.name] = { field => value.to_s }
      end

      # True when +name+ is declared as a collection on this class.
      def collection_attribute?(name)
        attr = attributes[name] || attributes[name.to_s]
        attr ? attr.collection? : false
      end

      # @api private
      def scalar_value?(value)
        !(value.nil? || value.is_a?(::Hash) || value.is_a?(::Array))
      end

      # True when +name+ is a declared attribute on this class, under either a
      # Symbol or a String key.
      def declared_attribute?(name)
        attributes.key?(name.to_sym) || attributes.key?(name.to_s)
      end

      # True when +name+ is declared on this class as a component (a nested
      # Serializable), rather than a plain scalar. The coercions are
      # type-aware: ~16 classes declare `edition` as a plain :string and must
      # keep the scalar they were given.
      def component_attribute?(name)
        attr = attributes[name] || attributes[name.to_s]
        return false unless attr

        type = attr.type
        type.is_a?(Class) && type <= Lutaml::Model::Serializable
      rescue StandardError
        false
      end

      # Serialization keys this class reads through a converter of its own
      # (a `key_value` rule declared with `with: {to:, from:}`). Those keys are
      # already handled and must not be rewritten underneath the flavor.
      #
      # Empty for a flavor with no `key_value` block, which serializes
      # attribute names directly.
      def converted_hash_keys
        @converted_hash_keys ||=
          begin
            rules = mappings[:hash]&.mappings || []
            rules.reject { |rule| rule.custom_methods.nil? || rule.custom_methods.empty? }
                 .map { |rule| rule.name.to_s }
          rescue StandardError
            []
          end
      end

      # The blessed constructor path (pubid#360 item 3).
      #
      # Two jobs, both of which lutaml declines to do:
      #
      #   * coerce a scalar into the component the attribute declares, so
      #     `edition: 2` and `year: 2023` work as written;
      #   * refuse a key this class does not know, instead of dropping it.
      #
      # The refusal is the important half. lutaml reads only declared attribute
      # names out of the hash (Serialize#initialize_attributes) and reports
      # nothing about the rest, so `new(number: "1000", year: 2023)` returned an
      # identifier with no year at all and no diagnostic — which is exactly how
      # the issue was filed. A dropped key is a silent wrong answer; a raise is
      # a loud one.
      #
      # Safe to apply here because neither internal rebuild path routes
      # attribute keys through the constructor: `from_hash` calls `new` with no
      # attributes and assigns through setters afterwards, and `#exclude`
      # rebuilds from `self.class.attributes` — only declared names, by
      # construction.
      #
      # @param attrs [Hash] caller-supplied attributes
      # @return [Hash] the same attributes, coerced
      # @raise [ArgumentError] naming every key this class does not declare
      def normalize_init_attributes(attrs)
        return attrs.dup unless attrs.is_a?(::Hash)

        normalized = attrs.dup
        fold_scalar_aliases(normalized)
        coerce_component_scalars(normalized)
        reject_unknown_keys(normalized)
        normalized
      end

      # Fold `year:` / `month:` / `day:` into the `date` component. Only when
      # the alias is not itself a declared attribute — ~20 flavors model the
      # edition as a plain `year` attribute, and folding there would destroy it.
      def fold_scalar_aliases(attrs)
        SCALAR_ATTRIBUTE_ALIASES.each do |alias_name, (target, field)|
          alias_str = alias_name.name
          key = attrs.key?(alias_name) ? alias_name : alias_str
          next unless attrs.key?(key)
          next if attributes.key?(alias_name) || attributes.key?(alias_str)
          next unless component_attribute?(target)

          value = attrs.delete(key)
          next if value.nil?

          target_str = target.name
          existing = attrs[target] || attrs[target_str] || {}
          existing = component_to_hash(existing)
          attrs.delete(target_str)
          attrs[target] = existing.merge(field => value.to_s)
        end
      end

      # Wrap a scalar in the component its attribute declares. A flavor that
      # declares the attribute as a plain :string keeps the scalar untouched.
      def coerce_component_scalars(attrs)
        FLAT_SCALAR_FIELDS.each do |attr_name, field|
          key = attrs.key?(attr_name) ? attr_name : attr_name.name
          next unless attrs.key?(key)
          next unless component_attribute?(attr_name)

          value = attrs[key]
          next if value.nil? || value.is_a?(::Hash) ||
            value.is_a?(Lutaml::Model::Serialize)

          attrs[key] = { field => value.to_s }
        end

        coerce_degenerate_components(attrs)
      end

      # Wrap a scalar in a degenerate component wherever the attribute declares
      # one, INCLUDING a collection — the residue of pubid#360 item 3.
      #
      # lutaml casts a Hash element into the component but passes a String
      # through untouched, so `languages: ["en"]` stored raw Strings and then
      # raised in the renderer (`undefined method 'code'`) and in the URN
      # generator. The Hash form `languages: [{code: "en"}]` already worked, so
      # this is a coercion gap, not a lutaml limit.
      def coerce_degenerate_components(attrs)
        attrs.keys.each do |key|
          next unless key.is_a?(::Symbol) || key.is_a?(::String)

          field = degenerate_field_for(key)
          next unless field

          attrs[key] = wrap_degenerate(attrs[key], field)
        end
      end

      # The degenerate field of the component +key+ declares, or nil when it
      # declares none. A collection attribute reports its ELEMENT class, so one
      # lookup covers both shapes; the `<=` test is what admits a flavor
      # subclass such as Pubid::Iec::Components::Publisher.
      def degenerate_field_for(key)
        type = declared_component_type(key)
        return nil unless type

        DEGENERATE_COMPONENT_FIELDS.find { |klass, _| type <= klass }&.last
      end

      # The component class +key+ declares, or nil when the attribute is
      # absent or declared as a plain scalar.
      def declared_component_type(key)
        type = (attributes[key.to_sym] || attributes[key.to_s])&.type
        type.is_a?(::Class) ? type : nil
      rescue StandardError
        nil
      end

      # A scalar becomes `{field => scalar}` and an Array is mapped
      # element-wise. nil, a Hash and an already-built component pass through
      # untouched, so every shape that worked before still works.
      def wrap_degenerate(value, field)
        if value.is_a?(::Array)
          return value.map { |v| wrap_degenerate(v, field) }
        end
        return value if value.nil? || value.is_a?(::Hash) ||
          value.is_a?(Lutaml::Model::Serialize)

        { field => value.to_s }
      end

      def reject_unknown_keys(attrs)
        allowed = RESERVED_INIT_KEYS + extra_init_keys
        unknown = attrs.keys.reject do |key|
          # A key that is neither a Symbol nor a String cannot name an
          # attribute, so it is unknown by definition — and `to_sym` on it
          # would raise NoMethodError instead of reporting that.
          next false unless key.is_a?(::Symbol) || key.is_a?(::String)

          allowed.include?(key.to_sym) || declared_attribute?(key)
        end
        return if unknown.empty?

        raise ArgumentError,
              "unknown attribute#{'s' if unknown.size > 1} for " \
              "#{name || self}: #{unknown.map(&:to_s).sort.join(', ')}"
      end

      # Constructor parameters a flavor accepts that are not lutaml attributes.
      # IEEE takes `code:` and `draft:` this way — runtime-only values its
      # `initialize` turns into component objects. Override to widen.
      #
      # @return [Array<Symbol>]
      def extra_init_keys
        []
      end

      # @api private
      def component_to_hash(value)
        case value
        when ::Hash then value.transform_keys(&:to_sym)
        when Lutaml::Model::Serialize then value.to_hash.transform_keys(&:to_sym)
        else {}
        end
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
          additional_identifier_classes +
          own_base_class).uniq
      end

      # The flavor's own Identifier base, when a builder instantiates it
      # directly (BSI does, for the members of a bundled identifier). Such an
      # object serializes with `_type: "pubid:<flavor>:identifier"`, and
      # without an entry here that type resolves to nothing — so a nested
      # polymorphic attribute typed ::Pubid::Identifier silently deserialized
      # the member as the abstract root instead of the flavor class. Added
      # LAST, so a concrete leaf that somehow claimed the same name still wins.
      def own_base_class
        return [] if self == ::Pubid::Identifier
        return [] unless name && polymorphic_name

        [self]
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
    # Plain strings, for every flavor. A Components::Code here held nothing
    # but its `value` on the identifier path, and the disagreement between
    # this declaration and the leaves that redeclared a scalar was the
    # determinism landmine: a redeclaration on an inherited-from class
    # resolves nondeterministically under multi-flavor load. With the base
    # declaring the scalar, no flavor redeclares and the bug class is gone.
    # A flavor that needs structure keeps its own attributes (ISO's committee
    # codes, NIST's series/subseries, ITU's code), never a boxed `number`.
    attribute :number, :string
    attribute :part, :string
    attribute :subpart, :string
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
    # "All parts" is a class, not a flag: see {Pubid::AllParts}. These two
    # readers keep a caller that read the old attribute working.
    # rubocop:disable Naming/PredicateMethod
    def all_parts
      false
    end
    # rubocop:enable Naming/PredicateMethod

    def all_parts?
      false
    end
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
      flatten_scalar_components(model, hash)
      # Nested components are not identifiers and have no such hook.
      if model.class.respond_to?(:compact_hash)
        model.class.compact_hash(model, hash)
      end
    end

    # A component that carries only ONE meaningful value serializes as that
    # value: `edition: "2"`, not `edition: {number: "2"}`; `year: "2024"`, not
    # `date: {year: "2024"}`. That is the shape an index row wants to be read
    # in, and the shape a caller can write without knowing pubid's component
    # classes — the complaint in pubid#360 item 3.
    #
    # The test is per INSTANCE, not per flavor, because one flavor's corpus
    # holds both shapes. Of 9,730 dated IEC identifiers, 9,728 carry a year
    # alone but 10 carry a month (`IEC CA 01:2025-10`) and 2 are undated
    # (`IEC 60050:--`); a flavor-wide switch would have discarded those.
    #
    # Flavors that already emit the flat form are untouched for free: IEC and
    # ISO serialize the date as top-level year/month/day, so no "date" key ever
    # reaches this method.
    def flatten_scalar_components(model, hash)
      flat_scalar_table(model).each do |attr_name, flat_key|
        flatten_scalar_component(model, hash, attr_name, flat_key)
      end
    end

    # The flat-scalar table of +model+'s class. The canonicalizer also runs on
    # nested components, which are not identifiers and have only the shared
    # tables.
    def flat_scalar_table(model, fields: false)
      klass = model.class
      if klass.respond_to?(:flat_scalar_components)
        fields ? klass.flat_scalar_fields : klass.flat_scalar_components
      else
        fields ? FLAT_SCALAR_FIELDS : FLAT_SCALAR_COMPONENTS
      end
    end

    # Replace +hash+'s serialization of +attr_name+ with a bare scalar, when
    # the component holds nothing but its single significant field.
    def flatten_scalar_component(model, hash, attr_name, flat_key)
      key = hash.key?(attr_name.to_s) ? attr_name.to_s : attr_name
      return unless hash.key?(key)
      return unless model.respond_to?(attr_name)

      field = flat_scalar_table(model, fields: true).fetch(attr_name)
      if hash[key].is_a?(::Array)
        return flatten_scalar_collection(model, hash, attr_name, key, field)
      end
      return unless hash[key].is_a?(::Hash)

      component = model.public_send(attr_name)
      return unless component.is_a?(Lutaml::Model::Serialize)

      scalar = degenerate_scalar(component, field)
      return if scalar.nil?
      # Never overwrite a key the flavor already emits under the flat name,
      # and never claim a name the flavor declares as a real attribute of its
      # own — ~20 flavors have a `year` attribute, and renaming `date` onto it
      # would make the two indistinguishable on the way back in.
      if flat_key != key.to_s
        return if hash.key?(flat_key) || model.class.declared_attribute?(flat_key)
      end

      replace_key_in_place(hash, key, flat_key, scalar)
    end

    # A collection of components (`copublishers`) serializes as a list of
    # scalars, but only when EVERY element is degenerate; a list that mixes
    # the two shapes could not be read back. The key keeps its name.
    def flatten_scalar_collection(model, hash, attr_name, key, field)
      components = model.public_send(attr_name)
      return unless components.is_a?(::Array) &&
        components.size == hash[key].size &&
        components.all?(Lutaml::Model::Serialize)

      scalars = components.map { |c| degenerate_scalar(c, field) }
      return if scalars.any?(&:nil?)

      hash[key] = scalars
    end

    # Replace +old_key+ with +new_key+ WITHOUT moving it to the end.
    #
    # A plain delete-then-assign appends, which would reorder every key after
    # the one being flattened — cosmetic for `==`, but it rewrites the byte
    # order of every generated relaton-data YAML row for no reason.
    def replace_key_in_place(hash, old_key, new_key, value)
      if old_key.to_s == new_key
        hash[old_key] = value
        return
      end

      rebuilt = hash.each_with_object({}) do |(k, v), acc|
        if k == old_key
          acc[new_key] = value
        else
          acc[k] = v
        end
      end

      hash.replace(rebuilt)
    end

    # The scalar +component+ degenerates to, or nil when it carries anything
    # besides +field+.
    #
    # A +field+ holding another component (ISO's edition number is a
    # Components::Code) is deliberately NOT flattened: the flat form would come
    # back as a plain String, so `from_hash(to_hash) == parse` would break —
    # the silent inequality that CLAUDE.md records as the costliest failure
    # mode in this codebase, because `#matches?` is built on `==`.
    def degenerate_scalar(component, field)
      register = component.lutaml_register
      found = nil

      component.class.attributes(register).each do |name, attr|
        value = component.public_send(name)
        # `Utils.empty?(nil)` is false, so nil needs its own test — an
        # unpopulated attribute is exactly what makes a component degenerate.
        next if value.nil? || Lutaml::Model::Utils.empty?(value)
        next if attr.default_set?(register, component) &&
          value == attr.default(register, component)
        return nil unless name == field
        return nil if value.is_a?(Lutaml::Model::Serialize)

        found = value
      end

      found&.to_s
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
            :canonicalize_nested, :canonicalize_collection,
            :flatten_scalar_components, :flatten_scalar_component,
            :flatten_scalar_collection, :flat_scalar_table,
            :degenerate_scalar, :replace_key_in_place

    def initialize(attrs = {}, options = {})
      attrs = self.class.normalize_init_attributes(attrs)
      attrs[:_type] ||= self.class.polymorphic_name
      super
    end

    # Pure function of the class name; relaton resolves it per registry
    # lookup and per cache-key build, so the kebab-case rebuild (two gsub
    # passes + interpolations) ran on every call — a top string
    # allocation site in metanorma's bibliography phase. Singleton ivars
    # are not inherited, so each concrete class memoizes its own.
    def self.polymorphic_name
      return nil unless name

      @pubid_polymorphic_name ||= begin
        parts = name.split("::")
        flavor = parts[1]&.downcase
        type_kebab = parts.last
          .gsub(/([A-Z]+)([A-Z][a-z])/, '\1-\2')
          .gsub(/([a-z\d])([A-Z])/, '\1-\2')
          .downcase
        "pubid:#{flavor}:#{type_kebab}"
      end
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

      # `:trademark` (IEEE) and `:with_volume` (ECMA) are render-time flags
      # consumed by the renderer, not the rendering context — and some flavors
      # override build_rendering_context with a strict signature, so strip them
      # here rather than widening that signature.
      ctx_opts = opts.except(:trademark, :with_volume)
      context = build_rendering_context(renderer, format:, **ctx_opts)
      render_opts = opts.slice(:with_edition, :trademark, :with_volume)
      result = renderer.new(self).render(context:, **render_opts)

      annotate_rendered(result, format, ctx_opts[:annotated], context)
    end

    # Apply semantic spans when the renderer did not.
    #
    # `context.annotated` reaches all 39 flavor renderers and all 39 ignore it,
    # so annotation was a v1 -> v2 regression for every flavor but ISO. This is
    # the single choke point every renderer already passes through, which is
    # why the fallback lives here rather than in each renderer.
    #
    # The `<span` test is what keeps ISO's exact, render-time placement: a
    # renderer that annotated itself is left alone.
    def annotate_rendered(result, format, annotated, context)
      return result unless annotated && format == :human
      return result unless result.is_a?(String)
      return result if result.include?("<span")

      Renderers::Annotator.new(self, context).annotate(result)
    end
    private :annotate_rendered

    # The same fallback, for a `to_s` that composes its string by hand instead
    # of going through {#render} — ITU, CCSDS, CIE and CSA wrappers all do.
    # Those never reach the choke point above, so they apply it on the way out.
    #
    # Every such `to_s` must also ACCEPT `annotated:`. Before they did, 13 type
    # families raised on the flag (`wrong number of arguments (given 1,
    # expected 0)` for the ones declaring no parameters at all), which is worse
    # than a missing span: a wrapper is exactly the shape a consumer renders.
    #
    # This is deliberately a per-class opt-in rather than a module prepended to
    # every identifier class. That was tried: prepending to ~500 ancestor
    # chains correlated with a GOST identical adoption rendering its adopted
    # ISO Technical Report as `ISO TR …` instead of `ISO/TR …`, but only under
    # full-suite load — the multi-flavor nondeterminism this file warns about
    # elsewhere. The correlation turned out not to be causal: the actual
    # defect was an unrelated foreign-adoption prefix-routing race in
    # `Gost::Builder` (`lib/pubid/gost/CLAUDE.md`), since fixed. The lesson
    # about not prepending stands anyway: an explicit call in the handful of
    # classes that need it changes no ancestor chain and cannot have that
    # effect.
    #
    # @param rendered [String] the plain rendering this method produced
    # @param opts [Hash] the render options it was called with
    # @return [String] annotated when `annotated:` was asked for, else as-is
    def annotate_plain_render(rendered, **opts)
      annotate_rendered(rendered, :human, opts[:annotated], nil)
    end
    protected :annotate_plain_render

    # The tokens {Renderers::Annotator} looks for in this identifier's rendered
    # string, as [attribute_name, css_class] pairs.
    #
    # The shared table names the components a printed identifier usually
    # carries — publisher, type, number, part, year. A flavor that keeps its
    # identity somewhere else answers with its own names appended: IEC's
    # working documents are `technical_committee`/`wd_number`/`wd_stage`, and
    # CSA's electrical code prints `cec_part`/`no_number` rather than the
    # `number` it stores. Without this they carried no annotatable token at all.
    #
    # Appending rather than replacing keeps whatever the shared table does
    # find; a token whose value is not in the string is skipped anyway.
    def annotation_tokens
      Renderers::Annotator::TOKENS
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

    # Hook for flavors whose identity includes a volume discriminator — ECMA-269
    # ed3 vol1..vol4 are four distinct documents sharing one docidentifier.
    # Literally nil here, NOT `volume&.to_s`: Pubid::Nist::Identifiers::Base
    # declares its own `volume` attribute with different MR semantics, so a
    # generic reader would change NIST's slug. A flavor that needs the segment
    # overrides this (see Pubid::Ecma::Identifier#mr_volume).
    def mr_volume
      nil
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

    # Attribute names on THIS class that hold a supplement's OWN identity
    # date — e.g. an Amendment's own publication year — as distinct from the
    # date of the document it supplements (reached one layer down, through
    # `base`/`identifiers`). Empty by default: nothing is protected, so
    # `exclude(:date)`/`exclude(:year)` fall straight through to every
    # declared attribute and every nested identifier, the shape almost every
    # flavor wants.
    #
    # A supplement leaf that owns its own date overrides this (CEN
    # `Amendment` `%i[year]`, CEN `Corrigendum` `%i[year month]`, BSI
    # `Amendment`/`Corrigendum` `%i[date]`). #exclude then protects those
    # attributes from a bare `:date`/`:year` — recursion into a *nested*
    # base/consolidated member is untouched, since recursion always uses the
    # caller's original args — and requires the explicit `:supplement_year`
    # key to clear them instead. This is what lets `exclude(:date)` on a
    # consolidated identifier drop the base standard's date while leaving an
    # attached amendment's own date alone, without a per-flavor #exclude
    # override.
    def self.supplement_date_attributes
      []
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

      own_date_attrs = self.class.supplement_date_attributes
      # A no-op when own_date_attrs is empty (Array#|/#- with [] returns the
      # receiver unchanged), which is every class that doesn't override the
      # hook — no guard needed.
      if excluded_args.include?(:supplement_year)
        excluded_args |= own_date_attrs
      else
        excluded_args -= own_date_attrs
      end

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
    # Compares #exclude, not #matches?: NIST overrides #matches? as an
    # asymmetric wildcard query (and takes no ignore: keyword).
    def dated_version_of?(other)
      return false unless other.is_a?(::Pubid::Identifier)

      exclude(:date, :year) == other.exclude(:date, :year) && self != other
    end

    # The attributes that carry a revision marker. Flavors spell it
    # differently: OGC and IEEE hold a string (+revision+), NIST folds the
    # lettered revision and its date into an +update+ component.
    REVISION_ATTRIBUTES = %i[revision update update_component].freeze

    # The revision marker this identifier carries, or nil. See
    # REVISION_ATTRIBUTES.
    # @return [String, Components::Update, nil]
    def revision_marker
      REVISION_ATTRIBUTES.each do |name|
        next unless self.class.attributes.key?(name)

        value = public_send(name)
        return value unless value.nil? || value == ""
      end
      nil
    end

    # Self is a revision of +other+: the same document, where self carries a
    # revision marker ("OGC 06-121r9", "NBS LC 800 rJun1992") that +other+
    # lacks or spells differently. A document whose revision is modelled as
    # an edition is covered by #edition_of? instead.
    def revision_of?(other)
      return false unless other.is_a?(::Pubid::Identifier)
      return false if self == other
      return false if revision_marker.nil?

      # #exclude, not #matches?: NIST overrides #matches? as an asymmetric
      # wildcard query (and takes no ignore: keyword), which would compare a
      # query against a candidate rather than two concrete documents.
      exclude(*REVISION_ATTRIBUTES) == other.exclude(*REVISION_ATTRIBUTES) &&
        revision_marker != other.revision_marker
    end

    # The document a wrapper stands in front of: a supplement's base, or
    # the leading member of a consolidated collection ("BS 7273-4:2015"
    # inside "BS 7273-4:2015+A1:2021"). Nil for a plain identifier.
    def wrapped_document
      return base if self.class.attributes.key?(:base) && base

      if self.class.collection_attribute?(:identifiers) &&
         identifiers.is_a?(Array) && identifiers.first
        return identifiers.first
      end

      nil
    end

    # The [publisher, number, part] tuple naming the document this
    # identifier belongs to, resolved through wrappers.
    def document_identity
      wrapped_document&.document_identity || [publisher, number, part]
    end

    # Self and +other+ have the same publisher + number but differ in
    # part, subpart, or edition. This is the "sibling documents" pattern:
    # same base standard, different sub-component. Two wrappers compare
    # through the document they wrap, so e.g. the amendments of one base
    # standard are siblings while amendments of different documents are
    # not.
    def sibling_of?(other)
      return false unless other.is_a?(::Pubid::Identifier)
      return false if self == other

      if wrapped_document && other.wrapped_document
        document_identity.take(2) == other.document_identity.take(2)
      else
        publisher == other.publisher &&
          number == other.number
      end
    end

    # The attributes that name a part of a document.
    PART_ATTRIBUTES = %i[part subpart parts].freeze

    # The class that #to_all_parts builds. A flavor with its own all-parts
    # behaviour returns its subclass of {AllPartsIdentifier} here.
    def self.all_parts_class
      ::Pubid::AllPartsIdentifier
    end

    # The attributes that name an edition of a document. An all-parts
    # identifier ignores them, so it matches every edition. #exclude skips a
    # name that a class does not declare, so one list serves every flavor; a
    # flavor with another edition shape overrides this.
    def self.all_parts_edition_keys
      %i[date year edition version]
    end

    # A new identifier for every part of this document. It holds this
    # identifier, unchanged, as its only member. `to_s` prints the document
    # without its part and edition ("ISO 9000 (all parts)"), and `===`
    # matches every part of it in every edition. The receiver does not change.
    # A parsed "(all parts)" still sets the +all_parts+ flag instead; the two
    # forms are not equal.
    # @return [Pubid::AllPartsIdentifier]
    def to_all_parts
      self.class.all_parts_class.new(identifiers: [self])
    end

    # @return [Boolean] true when this identifier names a part of a document
    def part?
      without_parts != normalized_copy
    end

    # A copy without `part`, `parts`, `subpart` and the +extra+ attributes.
    # Nested identifiers lose them too (#exclude).
    def without_parts(*extra)
      normalized_copy(*PART_ATTRIBUTES, *extra)
    end

    # A copy without the +attrs+ (#exclude), where a part collection holds
    # [] and never nil. A parse and #from_hash disagree on nil against [] in
    # some flavors (JIS), so two copies compare equal only after this.
    def normalized_copy(*attrs)
      exclude(*attrs).tap do |id|
        PART_ATTRIBUTES.each do |name|
          next unless self.class.collection_attribute?(name)

          id.public_send(:"#{name}=", []) if id.public_send(name).nil?
        end
      end
    end
    protected :without_parts, :normalized_copy

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
        exclude(:date, :year, :stage, :typed_stage) ==
          other.exclude(:date, :year, :stage, :typed_stage)
    end

    # Self and +other+ are editions of the same document: the edition-year
    # pair ("ISO 9001:2008" → "ISO 9001:2015"), or two consolidated states
    # of one base document — "BS 7273-4:2015+A1:2021" is the prior edition
    # of "BS 7273-4:2015+A2:2023" (pubid/pubid#449). A composite and its
    # unwrapped base are not editions of each other: bare → +A1 → +A2 is a
    # supersession series, not an edition-year relationship — the amendment
    # supplements the base without superseding it.
    def edition_of?(other)
      return false unless other.is_a?(::Pubid::Identifier)
      return false if self == other

      if wrapped_document && other.wrapped_document
        document_identity == other.document_identity
      else
        publisher == other.publisher &&
          number == other.number &&
          part == other.part
      end
    end

    # Any relational predicate holds.
    def related_to?(other)
      %i[supplement_of? has_supplement? dated_version_of? edition_of?
         revision_of? sibling_of? includes? draft_of?].any? do |m|
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
