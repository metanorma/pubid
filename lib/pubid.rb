# frozen_string_literal: true

require "lutaml/model"
require "parslet"

# Eagerly load the Lutaml::Model patch (disables reference store to avoid
# unbounded memory growth during bulk parsing, and adds a default +to_urn+
# implementation to every Serializable). This must apply before any Pubid
# code runs.
require "pubid/lutaml/no_store_registration"

# Uniform, static per-flavor prefix API (Pubid::<Flavor>.prefixes). Required
# before the flavor autoloads below so each flavor file can `extend` it and the
# central JOINT_PREFIXES constant is visible when its PREFIXES is defined.
require "pubid/prefixes_support"

module Pubid
  autoload :Schema, "pubid/schema"
  autoload :Conformance, "pubid/conformance"
  autoload :Parg, "pubid/parg"
  # Upper bound on the length of an identifier string accepted by any +parse+
  # entry point. Real-world standards identifiers are well under 200 characters;
  # this limit exists purely to keep pathological, attacker-controlled inputs
  # away from the flavors' backtracking-capable normalization regexes
  # (CodeQL rb/polynomial-redos). The inline `.length` checks in every public
  # +parse+ method are recognized by CodeQL as a barrier that bounds the input
  # before it can reach those regexes. Ruby 3.2+ already memoizes the flagged
  # regexes to linear time, so this guard is defense-in-depth, not a fix for a
  # live exploit; it must therefore never reject a legitimate identifier.
  MAX_INPUT_LENGTH = 1000

  # Raised (as an ArgumentError) when an input string exceeds MAX_INPUT_LENGTH.
  INPUT_TOO_LONG_MESSAGE =
    "identifier string exceeds maximum length of #{MAX_INPUT_LENGTH} characters"

  # Raised (as an ArgumentError) when +parse+ gets something that is not a
  # String. Without this check the input reaches +.length+ and the caller gets a
  # NoMethodError ("undefined method 'length' for nil"), a Ruby internal error
  # that says nothing about the identifier contract. Every public +parse+ entry
  # point rejects a non-String before it measures the length.
  INPUT_NOT_A_STRING_MESSAGE = "identifier must be a String"

  # Registry for tracking all loaded flavors
  class Registry
    @flavors = {}

    class << self
      # The registered flavors, always key-sorted and frozen. Sorted so
      # no behavior can observe registration (= module load) order -
      # hosts autoload flavor modules in any order, and order-dependent
      # iteration once routed the same identifier to different flavors
      # per process. Frozen so the raw table is not public mutable
      # state; #register is the only mutator.
      # @return [Hash{String => Module}]
      def flavors
        @flavors.sort.to_h.freeze
      end

      # Register a flavor with the registry
      # @param name [String, Symbol] Flavor name (e.g., :iso, :iec)
      # @param flavor_module [Module] The flavor module (e.g., Pubid::Iso)
      def register(name, flavor_module)
        @flavors[name.to_s.downcase] = flavor_module
      end

      # Remove a flavor registration. Tests that register probe flavors
      # MUST unregister them: registry-driven specs enumerate every
      # registered flavor, so a leaked probe fails them for everyone
      # else in the process.
      # @param name [String, Symbol] Flavor name
      def unregister(name)
        @flavors.delete(name.to_s.downcase)
      end

      # Get all registered flavor names
      # @return [Array<String>] Array of flavor names
      def flavor_names
        @flavors.keys.sort
      end

      # Get flavor module by name
      # @param name [String, Symbol] Flavor name
      # @return [Module, nil] The flavor module or nil if not found
      def get(name)
        @flavors[name.to_s.downcase]
      end

      # The canonical registered name of a module that may be registered
      # under aliases (CenCenelec registers both cen_cenelec and cen).
      # Canonical = the name the module's own prefix table is keyed by,
      # so the answer cannot depend on registration or iteration order.
      # @param flavor_module [Module]
      # @return [String, nil]
      def canonical_name(flavor_module)
        if flavor_module.singleton_class.method_defined?(:prefix_flavor_key)
          key = flavor_module.prefix_flavor_key.to_s
          return key if @flavors[key] == flavor_module
        end
        @flavors.key(flavor_module)
      end

      # Check if a flavor is registered
      # @param name [String, Symbol] Flavor name
      # @return [Boolean]
      def registered?(name)
        @flavors.key?(name.to_s.downcase)
      end

      # Parse an identifier without naming its flavor.
      #
      # The pubid 1.x entry point, kept because consumers still call it —
      # isodoc's +std_docid_semantic_parse+ among them. It delegates to
      # {Pubid.parse}; it is not a second implementation.
      #
      # @param string [String] the identifier string
      # @return [Pubid::Identifier]
      # @raise [Parslet::ParseFailed] when no flavor can parse it
      def parse(string, **opts)
        Pubid.parse(string, **opts)
      end

      # Build an identifier from its hash without naming its flavor.
      # It delegates to {Pubid.from_hash}, as {parse} delegates to
      # {Pubid.parse}.
      #
      # @param data [Hash] an identifier hash
      # @return [Pubid::Identifier]
      # @raise [Pubid::Errors::InvalidInputError] see {Pubid.from_hash}
      def from_hash(data)
        Pubid.from_hash(data)
      end
    end
  end

  # Canonical joint / co-publication leading tokens, sourced at boot from
  # schema/core/joint_prefixes.yaml - the single source of truth. Injected
  # symmetrically into every participating flavor's +prefixes+ (see
  # {PrefixesSupport}) so co-publication symmetry can never drift. Keyed by
  # {PrefixesSupport#prefix_flavor_key}.
  JOINT_PREFIXES = Schema::Loader.joint_prefixes_map
    .transform_keys(&:to_sym).freeze

  autoload :Errors, "pubid/errors"
  autoload :Parser, "pubid/parser"
  autoload :Components, "pubid/components"
  autoload :BundledIdentifier, "pubid/bundled_identifier"
  autoload :AllParts, "pubid/all_parts"
  autoload :AllPartsIdentifier, "pubid/all_parts_identifier"
  autoload :Identifier, "pubid/identifier"
  autoload :SubsetMatch, "pubid/subset_match"
  autoload :IdentifierMetadata, "pubid/identifier_metadata"
  autoload :Rendering, "pubid/rendering"
  autoload :Renderers, "pubid/renderers"
  autoload :FormatDetector, "pubid/format_detector"
  autoload :FormatRegistry, "pubid/format_registry"

  autoload :UrnGenerator, "pubid/urn_generator/base"
  autoload :UrnParser, "pubid/urn_parser"
  autoload :Builder, "pubid/builder/base"
  autoload :Utils, "pubid/utils"
  autoload :Version, "pubid/version"
  autoload :Core, "pubid/core"
  autoload :TypeResolver, "pubid/type_resolver"


  # Require all flavor modules
  autoload :Adobe, "pubid/adobe"
  autoload :Amca, "pubid/amca"
  autoload :Ansi, "pubid/ansi"
  autoload :Api, "pubid/api"
  autoload :Ashrae, "pubid/ashrae"
  autoload :Asme, "pubid/asme"
  autoload :Doi, "pubid/doi"
  autoload :Easc, "pubid/easc"
  autoload :Astm, "pubid/astm"
  autoload :Bipm, "pubid/bipm"
  autoload :Bsi, "pubid/bsi"
  autoload :Calconnect, "pubid/calconnect"
  autoload :Ccsds, "pubid/ccsds"
  autoload :CenCenelec, "pubid/cen_cenelec"
  autoload :Cie, "pubid/cie"
  autoload :Csa, "pubid/csa"
  autoload :Ecma, "pubid/ecma"
  autoload :Etsi, "pubid/etsi"
  autoload :Evs, "pubid/evs"
  autoload :Gost, "pubid/gost"
  autoload :Gb, "pubid/gb"
  autoload :Idf, "pubid/idf"
  autoload :Iec, "pubid/iec"
  autoload :Ieee, "pubid/ieee"
  autoload :Ietf, "pubid/ietf"
  autoload :Isbn, "pubid/isbn"
  autoload :Iala, "pubid/iala"
  autoload :Iana, "pubid/iana"
  autoload :Iho, "pubid/iho"
  autoload :Iso, "pubid/iso"
  autoload :Itu, "pubid/itu"
  autoload :Jcgm, "pubid/jcgm"
  autoload :Jis, "pubid/jis"
  autoload :Nist, "pubid/nist"
  autoload :Oasis, "pubid/oasis"
  autoload :Ogc, "pubid/ogc"
  autoload :Oiml, "pubid/oiml"
  autoload :Omg, "pubid/omg"
  autoload :Plateau, "pubid/plateau"
  autoload :Export, "pubid/export"
  autoload :Sae, "pubid/sae"
  autoload :Tgpp, "pubid/tgpp"
  autoload :Un, "pubid/un"
  autoload :Xsf, "pubid/xsf"
  autoload :W3c, "pubid/w3c"

  # Format infrastructure (loaded eagerly so Pubid::Renderers / Pubid::Parsers are always available)
  require "pubid/renderers/base"
  require "pubid/renderers/mr_string"
  require "pubid/renderers/urn"
  require "pubid/parsers/base"
  require "pubid/parsers/mr_string"
  require "pubid/parsers/urn"

  # Initialize global format registry
  Identifier.format_registry = FormatRegistry.new
  Identifier.format_registry.register(:human, renderer: Renderers::HumanReadable)
  Identifier.format_registry.register(:mr_string, renderer: Renderers::MrString)
  Identifier.format_registry.register(:urn, renderer: Renderers::Urn,
                                       parser: Parsers::Urn)

  # Unified parse entry point with auto-detection
  #
  # A human-readable string is routed to its owning flavor by leading prefix
  # token, using the {prefix_flavors} table. This restores the pubid 1.x
  # +Pubid::Registry.parse+ capability, which isodoc still calls; before it,
  # this method raised +No flavor specified+ for every human-readable string,
  # so a reference whose flavor the caller did not already know could not be
  # parsed at all.
  #
  # @param string [String] The identifier string to parse
  # @param format [Symbol] :auto, :human, :mr_string, or :urn
  # @return [Identifier] The parsed identifier
  # @raise [ArgumentError] for a non-String, or one over {MAX_INPUT_LENGTH}
  # @raise [Parslet::ParseFailed] when no flavor can parse the string — the
  #   class every flavor's own +parse+ raises (see the parse-failure contract)
  def self.parse(string, format: :auto)
    unless string.is_a?(String)
      raise Pubid::Errors::InvalidInputError,
            Pubid::INPUT_NOT_A_STRING_MESSAGE
    end
    if string.length > MAX_INPUT_LENGTH
      raise Pubid::Errors::InvalidInputError,
            Pubid::INPUT_TOO_LONG_MESSAGE
    end

    format = FormatDetector.detect(string) if format == :auto

    case format
    when :mr_string
      # The MR detector is a shape heuristic (`/\A[A-Z]{2,}[.-]/`), and some
      # human-readable identifiers have that shape — "ITU-T G.711" is the
      # standing example. Fall through to prefix routing when the MR parse
      # fails, rather than reporting an MR error for a string that was never
      # an MR string. A genuine MR failure still surfaces, from the second
      # attempt, as Parslet::ParseFailed.
      #
      # Narrow, for the reason spelled out on {parse_by_prefix}: only a parse
      # failure means "wrong shape". Anything else is a defect and propagates.
      begin
        Parsers::MrString.parse(string)
      rescue Parslet::ParseFailed
        parse_by_prefix(string)
      end
    when :urn
      parse_urn(string)
    else
      parse_by_prefix(string)
    end
  end

  # Parse an identifier URN, detecting the flavor from the URN namespace
  # and delegating to the flavor's UrnParser. This is also the :urn
  # format's parse side (Parsers::Urn), which the Lutaml FormatRegistry
  # mirror exposes as Identifier.from_urn.
  #
  # @param string [String] the URN
  # @return [Identifier] the parsed identifier
  def self.parse_urn(string)
    eager_load_flavors!
    flavor = detect_flavor_from_urn(string)
    flavor_module = Registry.get(flavor)
    unless flavor_module
      raise ArgumentError,
            "Unknown flavor in URN: #{flavor}"
    end

    urn_parser = flavor_module.const_get(:UrnParser)
    urn_parser.parse(string)
  end

  # Build an identifier from its serialized hash, without naming its flavor —
  # the hash counterpart of {parse}.
  #
  # The hash is what {Identifier#to_hash} emits, and what a relaton-data
  # +index-v2.yaml+ row stores under +:id+. Its +_type+ key
  # ("pubid:<flavor>:<type>") names the concrete class, so no prefix guessing
  # is necessary. The class is resolved by {TypeResolver}, and the class's own
  # +from_hash+ does the rest, nested identifiers of other flavors included.
  #
  # @example
  #   Pubid.from_hash("_type" => "pubid:iso:international-standard",
  #                   "number" => "9001", "year" => "2015").to_s
  #   # => "ISO 9001:2015"
  #
  # @param data [Hash] an identifier hash. String and Symbol keys are both
  #   accepted.
  # @return [Identifier] an instance of the class that +_type+ names
  # @raise [Pubid::Errors::InvalidInputError] when +data+ is not a Hash, has no
  #   +_type+, or has a +_type+ that no registered flavor defines. These are
  #   the only failures it translates: once +_type+ names a class, an error
  #   from that class's own +from_hash+ (a malformed field, or a bad +_type+
  #   in a NESTED hash) propagates unchanged, so a flavor defect is not
  #   disguised as bad input.
  def self.from_hash(data)
    unless data.is_a?(Hash)
      raise Pubid::Errors::InvalidInputError,
            "identifier data must be a Hash, got #{data.class}"
    end

    identifier_class_for(data).from_hash(data)
  end

  # The concrete class that the +_type+ of +data+ names.
  #
  # @param data [Hash] an identifier hash
  # @return [Class<Identifier>]
  # @raise [Pubid::Errors::InvalidInputError] no +_type+, or an unknown one
  # @api private
  def self.identifier_class_for(data)
    type = data["_type"] || data[:_type]
    unless type
      raise Pubid::Errors::InvalidInputError,
            "identifier hash has no _type key: #{data.inspect[0, 200]}"
    end

    TypeResolver.resolve(type) ||
      raise(Pubid::Errors::InvalidInputError,
            "unknown identifier _type: #{type.inspect}")
  end
  private_class_method :identifier_class_for

  # Route a human-readable identifier to its flavor by leading prefix token.
  #
  # Three passes, widening each time — the pubid 1.x +Registry.parse+ shape:
  #
  #   1. flavors owning the longest matching prefix ("ISO/IEC" before "ISO")
  #   2. every other flavor, in registry order
  #
  # A longest-match-first order matters because prefixes nest: "ISO/IEC 2131"
  # must not be handed to the flavor that merely owns "ISO".
  #
  # @param string [String] a human-readable identifier
  # @return [Identifier]
  # @raise [Parslet::ParseFailed] when no flavor accepts the string
  # @api private
  def self.parse_by_prefix(string)
    eager_load_flavors!

    first_error = nil
    fallback = nil

    prefix_owners = candidates_by_prefix(string)
    (prefix_owners + other_candidates(prefix_owners)).each do |mod|
      begin
        parsed = mod.parse(string)
      rescue Parslet::ParseFailed => e
        # ONLY a parse failure means "not this flavor's identifier". Every
        # other exception is a defect in that flavor and must propagate.
        #
        # A blanket `rescue StandardError` here would swallow exactly the
        # `ArgumentError: unknown attribute…` that the constructor contract on
        # `Identifier` now raises — the error that turned three silent
        # data-loss bugs (CIE `s_prefix`, IEEE `adopted_identifier`,
        # IEEE `csa_identifier`) into visible ones. Catching it one layer up
        # would hand it straight back its disguise: a real builder bug in any
        # flavor would read as "this string is not an identifier".
        first_error ||= e
        next
      end

      # An exact round trip is the strongest evidence the string belongs to
      # this flavor. It matters because some grammars accept anything by
      # design — adobe and iana take any slug — so without it the first such
      # flavor in registry order claims every unclaimed string and invents
      # structure that was not in the input. Same test isodoc applies before
      # it will annotate a parsed id.
      return parsed if parsed.to_s == string

      # A non-exact parse is still usable, but only from a flavor with an
      # actual claim on the string — several flavors legitimately normalise
      # on render, so the round trip is a preference, not a requirement (OGC
      # prints `06-121r9` for `OGC 06-121r9`, and 32 ASHRAE / ASME / CSA /
      # IEEE identifiers route only this way). What it must NOT come from is
      # a flavor without a claim, whatever the claim-miss looks like: a
      # flavor that accepts anything (`iec.60050` came back as `IANA
      # iec.60050`), or a flavor whose grammar only parses the string by
      # defaulting what the input never spelled (iec answers `CIE` with
      # `IEC CIE`, astm answers `123` with `ASTM 123`). Reporting that no
      # flavor could be determined beats inventing one.
      next unless prefix_owners.include?(mod)
      fallback ||= parsed unless accepts_anything?(mod)
    end

    return fallback if fallback
    raise first_error if first_error

    raise Parslet::ParseFailed,
          "no registered flavor could parse #{string.inspect}"
  end
  private_class_method :parse_by_prefix

  # Flavor modules that own a prefix +string+ starts with, longest prefix
  # first. Deduplicated by module identity, so an alias registration is not
  # tried twice.
  #
  # These are the flavors with an actual claim on the string; a parse from one
  # of them is trusted even when the flavor normalises on render.
  #
  # @param string [String] a human-readable identifier
  # @return [Array<Module>]
  # @api private
  def self.candidates_by_prefix(string)
    ordered = []
    routing_table.each do |prefix, modules|
      ordered.concat(modules) if prefix_match?(string, prefix)
    end
    ordered.compact.uniq
  end
  private_class_method :candidates_by_prefix

  # Every other registered flavor, for the exhaustive second pass.
  #
  # @param exclude [Array<Module>] modules already tried
  # @return [Array<Module>]
  # @api private
  def self.other_candidates(exclude)
    ordered = []
    each_prefix_flavor_module { |mod| ordered << mod }
    ordered.compact.uniq - exclude
  end
  private_class_method :other_candidates

  # A meaningless string no real identifier scheme should claim. Used to find
  # the flavors whose grammar accepts anything.
  ROUTING_PROBE = "zzqx-nonsense-9714"
  private_constant :ROUTING_PROBE

  # True when +mod+'s grammar accepts an arbitrary slug.
  #
  # `adobe` and `iana` do, by design — their identifiers genuinely are free
  # text. That makes them unsafe as a fallback: whichever came first in
  # registry order would claim every string no other flavor matched, and
  # answer with structure the input never had.
  #
  # Detected by probing rather than by a hardcoded list, so a flavor that
  # acquires (or loses) an anything-goes grammar is classified correctly
  # without anyone remembering to edit a constant. Computed once per module.
  #
  # @param mod [Module] a flavor module
  # @return [Boolean]
  # @api private
  def self.accepts_anything?(mod)
    @accepts_anything ||= {}
    return @accepts_anything[mod] if @accepts_anything.key?(mod)

    @accepts_anything[mod] =
      begin
        mod.parse(ROUTING_PROBE)
        true
      rescue StandardError, Parslet::ParseFailed
        false
      end
  end
  private_class_method :accepts_anything?

  # Prefix => flavor modules, longest prefix first, built once.
  #
  # {prefix_flavors} rebuilds its index on every call, iterating every
  # registered flavor; routing consulted it twice per parse. The registry is
  # static once +eager_load_flavors!+ has run, so the table is memoised here
  # rather than making the public method's cost implicit.
  #
  # The memo is never invalidated, which is safe for every flavor shipped in
  # this gem — they are all +Pubid+-namespace constants that
  # +eager_load_flavors!+ loads before the first parse. A flavor registered
  # from OUTSIDE that namespace after the first {parse} call would miss its
  # prefix priority (it is still tried in the exhaustive second pass, so it is
  # reachable, just not preferred). Bust the memo in +Registry.register+ if
  # out-of-namespace flavors ever become a supported extension point.
  #
  # @return [Hash{String => Array<Module>}]
  # @api private
  def self.routing_table
    @routing_table ||= begin
      index = prefix_flavors
      index.keys
           .sort_by { |prefix| -prefix.length }
           .to_h { |prefix| [prefix, index[prefix].map { |key| Registry.get(key) }] }
    end
  end
  private_class_method :routing_table

  # True when +string+ starts with +prefix+ at a token boundary, so "ISO" does
  # not claim "ISOFIX" and "BS" does not claim "BSI". A boundary is the end
  # of the string or any non-alphanumeric character, so a registered prefix
  # can be followed by a space ("ISO 9001") or by a slash attaching a type
  # token ("ISO/TR 25901-1:2016").
  #
  # Public (not +@api private+) so a flavor's own prefix routing - GOST's
  # foreign-adoption lookup, currently the only caller outside this file -
  # can reuse the exact boundary rule {parse_by_prefix} uses, rather than
  # keeping a second copy that can drift out of sync.
  #
  # @param string [String]
  # @param prefix [String]
  # @return [Boolean]
  def self.prefix_match?(string, prefix)
    return false unless string.start_with?(prefix)

    rest = string[prefix.length]
    rest.nil? || !/[A-Za-z0-9]/.match?(rest)
  end

  def self.detect_flavor_from_urn(urn)
    # urn:iso:std:... → "iso"
    # urn:iec:std:... → "iec"
    # urn:mrn:iala:pub:... → "iala": MRN URNs carry an assigning authority
    # where ISO-style URNs carry their namespace, so routing follows the
    # authority (works for any future MRN assignee, not only IALA).
    parts = urn.downcase.split(":")
    return parts[2] if parts[1] == "mrn"

    parts[1] # The namespace part after "urn"
  end

  # Trigger autoloads for every declared flavor module so that
  # Registry is populated before URN dispatch needs it. Safe to call
  # repeatedly; no-op after the first invocation.
  #
  # The constant filter allows a digit inside the name (the +0-9+ in the regex)
  # so digit-bearing flavor modules such as +W3c+ are loaded/registered too —
  # without it +W3c+ is silently dropped from the registry enumeration and thus
  # from every registry-driven cross-flavor spec.
  def self.eager_load_flavors!
    return if @flavors_loaded

    constants.each do |c|
      next unless c.to_s.match?(/\A[A-Z][a-zA-Z0-9]+\z/)

      begin
        const_get(c)
      rescue StandardError
        nil
      end
    end
    @flavors_loaded = true
  end

  # Static leading prefix tokens for a single flavor.
  #
  # @param flavor [Symbol, String] a registered flavor name (e.g. +:iso+)
  # @return [Array<String>] the flavor's prefixes (see {PrefixesSupport})
  # @raise [ArgumentError] if the flavor is not registered
  def self.prefixes(flavor)
    mod = Registry.get(flavor)
    raise ArgumentError, "unknown flavor: #{flavor.inspect}" unless mod

    mod.prefixes
  end

  # Reverse index mapping every canonical prefix token to the flavor(s) that
  # own it — the exact routing table relaton needs. Co-published prefixes list
  # every co-publisher (e.g. +"ISO/IEC" => [:iec, :iso]+); see the inclusion /
  # exclusion policy documented on {PrefixesSupport}.
  #
  # The +:cen+ alias of +:cen_cenelec+ is de-duplicated by module identity, so a
  # prefix is attributed to a flavor's canonical
  # {PrefixesSupport#prefix_flavor_key} exactly once.
  #
  # @return [Hash{String => Array<Symbol>}] prefix token => sorted flavor keys,
  #   e.g. +{ "ISO" => [:iso], "ISO/IEC" => [:iec, :iso], ... }+
  def self.prefix_flavors
    index = Hash.new { |h, k| h[k] = [] }
    each_prefix_flavor_module do |mod|
      key = mod.prefix_flavor_key
      mod.prefixes.each { |prefix| index[prefix] |= [key] }
    end
    index.transform_values(&:sort).sort.to_h
  end

  # Yields each unique flavor module that exposes +prefixes+ exactly once,
  # collapsing alias registrations (e.g. +:cen+ and +:cen_cenelec+ both point to
  # +Pubid::CenCenelec+) by module identity.
  # @yieldparam mod [Module] a flavor module
  def self.each_prefix_flavor_module
    eager_load_flavors!
    seen = {}
    Registry.flavor_names.each do |flavor_name|
      mod = Registry.get(flavor_name)
      next if seen.key?(mod) || !mod.respond_to?(:prefixes)

      seen[mod] = true
      yield mod
    end
  end

  # Typed-stage lookup by abbreviation, across flavors.
  #
  # Each flavor module memoises +all_typed_stages+ over its own +Identifiers+
  # namespace, so an abbreviation only one flavor uses is invisible from any
  # other: +Pubid::Iso.locate_stage("ADTS")+ is nil while
  # +Pubid::Iec.locate_stage("ADTS")+ finds it. A consumer that holds an
  # abbreviation but not the owning flavor had nowhere to ask.
  #
  # @param abbr [String, Symbol] the stage abbreviation (case-insensitive)
  # @param flavor [Symbol, String, nil] search this flavor only; nil searches
  #   every registered flavor and returns the first match
  # @return [Object, nil] the flavor's typed-stage object, or nil. The class is
  #   flavor-specific: most return {Pubid::Components::TypedStage}, but IEEE
  #   has its own +Ieee::Components::TypedStage+, which is not a subclass.
  # @raise [ArgumentError] if +flavor+ names a flavor that is not registered
  def self.locate_stage(abbr, flavor: nil)
    return locate_stage_in(Registry.get(flavor), abbr, flavor) if flavor

    each_stage_flavor_module do |mod|
      stage = mod.locate_stage(abbr)
      return stage if stage
    end
    nil
  end

  # Every flavor that knows +abbr+ — the diagnostic companion to
  # {locate_stage}, for telling a consumer which module owns a stage.
  #
  # @param abbr [String, Symbol] the stage abbreviation (case-insensitive)
  # @return [Array<Symbol>] registered flavor keys, sorted
  def self.locate_stage_flavors(abbr)
    found = []
    each_stage_flavor_module do |mod, flavor_name|
      found << flavor_name.to_sym if mod.locate_stage(abbr)
    end
    found.sort
  end

  # Yields each unique flavor module that implements +locate_stage+, exactly
  # once. Three registered flavors (adobe, easc, gost) define no typed stages
  # at all, so a cross-flavor sweep must skip them rather than raise on the
  # first one it reaches; alias registrations are collapsed by module identity,
  # as in {each_prefix_flavor_module}.
  #
  # @yieldparam mod [Module] a flavor module
  # @yieldparam flavor_name [String] the registry key it was reached under
  def self.each_stage_flavor_module
    eager_load_flavors!
    seen = {}
    Registry.flavor_names.each do |flavor_name|
      mod = Registry.get(flavor_name)
      next if seen.key?(mod) || !mod.respond_to?(:locate_stage)

      seen[mod] = true
      yield mod, flavor_name
    end
  end

  # @api private
  def self.locate_stage_in(mod, abbr, flavor)
    raise ArgumentError, "unknown flavor: #{flavor.inspect}" unless mod
    return nil unless mod.respond_to?(:locate_stage)

    mod.locate_stage(abbr)
  end
  private_class_method :locate_stage_in
end
