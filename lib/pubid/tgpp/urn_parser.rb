# frozen_string_literal: true

module Pubid
  module Tgpp
    # Parses 3GPP URNs back into identifiers.
    #
    # UrnGenerator emits `urn:3gpp:<type>:<code>:<release>:<version>`; the code,
    # release and version chunks never contain ":", so a plain split recovers
    # them. Example: urn:3gpp:ts:23.207:REL-4:2.0.0 → TS 23.207:REL-4/2.0.0
    class UrnParser < Pubid::UrnParser::Base
      # The module is Tgpp but the URN namespace is "3gpp".
      def flavor_name
        "3gpp"
      end

      def parse_urn(urn)
        body = strip_namespace(urn)
        type, code, release, version = split_parts(body)
        # A partial identifier drops its trailing segments, and the no-release
        # form (e.g. TS 29.215/2.0.0) serialises with an empty release chunk
        # ("urn:3gpp:ts:29.215::2.0.0"). Rebuild only the segments present, so
        # neither the release colon nor the version slash dangles.
        result = "#{type.upcase} #{code}"
        result += ":#{release}" unless release.nil? || release.empty?
        result += "/#{version}" unless version.nil? || version.empty?
        flavor_parse(result)
      end
    end
  end
end
