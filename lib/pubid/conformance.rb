# frozen_string_literal: true

require "yaml"
require "json"

module Pubid
  # The shared, language-independent conformance corpus (conformance/).
  # The identifier structure in each case is THE GEM'S OWN canonical
  # to_hash, embedded verbatim (the same wire format relaton persists).
  # Nothing is reinvented: the corpus adds only what the gem cannot know -
  # representations, normalization aliases, styling, and neutral error
  # codes for debt/negative records.
  module Conformance
    autoload :Generator, "pubid/conformance/generator"
    autoload :Runner, "pubid/conformance/runner"

    # Neutral error vocabulary. Each implementation maps its native
    # exceptions onto these codes; the corpus never records Ruby classes.
    ERROR_CODES = {
      "Parslet::ParseFailed" => "parse_failed",
      "ArgumentError" => "invalid_argument",
    }.freeze

    class << self
      def error_code_for(exception)
        ERROR_CODES.fetch(exception.class.name, "unclassified")
      end

      # Heuristic PubID styling version. v1 = legacy "ISO/R 2533/3-1975";
      # v2 = dotted/uppercase ("AMD.1"); v3 = modern ("Amd 1"). Heuristic
      # until the model exposes its parsed format (TODO.restructure/12).
      def style_for(input)
        return "v1" if /\bISO\/R\b|\bISO R\b/.match?(input)
        return "v2" if /\b(?:Amd|AMD|Cor|COR|Suppl|SUPPL)\.\d/.match?(input)

        "v3"
      end

      # Hygiene only (not a redesign): guarantee the corpus is pure YAML -
      # component objects leaking through serialization are reduced to
      # their string rendering.
      def plainify(value)
        case value
        when Hash then value.to_h { |key, entry| [key.to_s, plainify(entry)] }
        when Array then value.map { |entry| plainify(entry) }
        when String, Integer, Float, TrueClass, FalseClass, NilClass then value
        else value.to_s
        end
      end
    end
  end
end
