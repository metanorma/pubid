# frozen_string_literal: true

require "yaml"
require "json"

module Pubid
  # The shared, language-independent conformance corpus (conformance/).
  # Each case records the semantic component tree of the identifier (which
  # part is which flavor-specific component) plus every proper
  # representation the reference implementation emits. A second
  # implementation (pubid-ts) rebuilds identifiers from the tree and must
  # reproduce every representation. Ground-truth inputs come from the
  # fixture library; debt (unparseable pass fixtures) is recorded visibly,
  # never dropped.
  module Conformance
    autoload :Generator, "pubid/conformance/generator"
    autoload :Runner, "pubid/conformance/runner"

    class << self
      # Canonical component tree for a canonical to_hash: _type becomes the
      # semantic type key (dashes normalized to schema keys), scalar and
      # array component values are grouped under components, and a nested
      # base recurses with the same shape.
      # Corpus data must be pure YAML: nested component objects that leak
      # through lutaml's nested serialization are reduced to their string
      # rendering so no ruby/object tags ever reach the corpus.
      def plainify(value)
        case value
        when Hash then value.to_h { |key, entry| [key.to_s, plainify(entry)] }
        when Array then value.map { |entry| plainify(entry) }
        when String, Integer, Float, TrueClass, FalseClass, NilClass then value
        else value.to_s
        end
      end

      # Heuristic PubID styling version per input string. v1 = legacy
      # "ISO/R 2533/3-1975" forms; v2 = classic dotted/uppercase supplement
      # spellings ("ISO 9001:2001/AMD.1:2010"); v3 = modern ("Amd 1:2010").
      # Heuristic until the model exposes its parsed format natively
      # (TODO.restructure/12).
      def style_for(input)
        return "v1" if /\bISO\/R\b|\bISO R\b/.match?(input)
        return "v2" if /\b(?:Amd|AMD|Cor|COR|Suppl|SUPPL)\.\d/.match?(input)

        "v3"
      end

      def component_tree(hash)
        components = {}
        base = nil
        hash.each do |key, value|
          case key
          when "_type" then next
          when "base" then base = component_tree(value)
          else components[key] = plainify(value)

          end
        end
        tree = {
          "type" => hash.fetch("_type", "").split(":").last.tr("-", "_"),
          "components" => components,
        }
        tree["base"] = base if base
        tree
      end
    end
  end
end
