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

      # Check if a flavor is registered
      # @param name [String, Symbol] Flavor name
      # @return [Boolean]
      def registered?(name)
        @flavors.key?(name.to_s.downcase)
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

  autoload :Parser, "pubid/parser"
  autoload :Components, "pubid/components"
  autoload :BundledIdentifier, "pubid/bundled_identifier"
  autoload :Identifier, "pubid/identifier"
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

  # Initialize global format registry
  Identifier.format_registry = FormatRegistry.new
  Identifier.format_registry.register(:human, renderer: Renderers::HumanReadable)
  Identifier.format_registry.register(:mr_string, renderer: Renderers::MrString)
  Identifier.format_registry.register(:urn, renderer: Renderers::Urn)

  # Unified parse entry point with auto-detection
  #
  # @param string [String] The identifier string to parse
  # @param format [Symbol] :auto, :human, :mr_string, or :urn
  # @return [Identifier] The parsed identifier
  def self.parse(string, format: :auto)
    if string.length > MAX_INPUT_LENGTH
      raise ArgumentError, 
            INPUT_TOO_LONG_MESSAGE
    end

    format = FormatDetector.detect(string) if format == :auto

    case format
    when :mr_string
      Parsers::MrString.parse(string)
    when :urn
      eager_load_flavors!
      flavor = detect_flavor_from_urn(string)
      flavor_module = Registry.get(flavor)
      unless flavor_module
        raise ArgumentError,
              "Unknown flavor in URN: #{flavor}"
      end

      urn_parser = flavor_module.const_get(:UrnParser)
      urn_parser.parse(string) else
      # Default to MR string parser for MR format, human-readable otherwise
      # The MR string parser converts to human-readable and delegates to flavor.parse
      raise ArgumentError,
            "No flavor specified. Use Pubid::Iso.parse() or another flavor-specific parse method."
    end
  end

  def self.detect_flavor_from_urn(urn)
    # urn:iso:std:... → "iso"
    # urn:iec:std:... → "iec"
    parts = urn.downcase.split(":")
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
end
