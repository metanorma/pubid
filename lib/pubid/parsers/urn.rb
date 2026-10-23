# frozen_string_literal: true

module Pubid
  module Parsers
    # The :urn format's parse side. The Lutaml FormatRegistry mirror
    # exposes it as Identifier.from_urn — the surface relaton-bib calls.
    # It had a renderer but no parser, so every from_urn raised
    # InvalidFormatError (metanorma-pdfa#108). Detects the flavor from
    # the URN namespace and delegates to the flavor's UrnParser.
    module Urn
      module_function

      def call(string)
        Pubid.parse_urn(string)
      end
    end
  end
end
