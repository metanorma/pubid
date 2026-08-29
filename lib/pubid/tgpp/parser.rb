# frozen_string_literal: true

require "parslet"

module Pubid
  module Tgpp
    # Parslet grammar for 3GPP identifiers.
    #
    # Form: `[3GPP ]<TR|TS> <NN.NNN>[suffix][-part…][:<release>][/<version>]`
    #   TS 23.207:REL-4/2.0.0
    #   3GPP TR 00.01U:UMTS/3.0.0
    #   TS 29.198-04-1:REL-5/5.0.0
    #   TS 02.68:Release 2000/9.0.0
    #   3GPP TS 23.207                (bare reference)
    #
    # The release and the version are both optional: a user reference names the
    # document alone ("3GPP TS 23.207"), and relaton parses that bare form to
    # search the index. Only the type and the dotted number core are required,
    # so "TS" and "TS foo" are still rejected.
    class Parser < Parslet::Parser
      rule(:digit) { match["0-9"] }
      rule(:digits) { digit.repeat(1) }
      rule(:space) { str(" ") }

      # Optional leading publisher token.
      rule(:publisher_prefix) { str("3GPP") >> space }

      # Document type.
      rule(:type) { (str("TR") | str("TS")).as(:type) }

      # Dotted number core, kept as a string (preserves leading zeros).
      rule(:number_core) { (digits >> str(".") >> digits).as(:number) }

      # Letter suffix directly after the number ("U"/"dcs"/"ext"…). Generic so
      # future controlled-vocabulary values keep round-tripping.
      rule(:suffix) { match["A-Za-z"].repeat(1).as(:suffix) }

      # Hyphen parts.
      rule(:part) { str("-") >> digits.as(:part) }
      rule(:parts) { part.repeat(0).as(:parts) }

      # Release token, stored verbatim: everything up to the version separator.
      # Excludes ":" (as well as "/") so the ":"-delimited URN scheme can always
      # encode it — every real release ("REL-4", "Ph1", "UMTS", "Release 2000")
      # is colon-free.
      #
      # A trailing segment shaped exactly like a version is a mistyped "/"
      # separator ("TS 23.207:2.0.0"), not a release: no release in the 88,464
      # published index rows contains a dot at all. Reject it rather than
      # silently misfiling the version as the release — which only became
      # reachable once the version segment was made optional.
      rule(:release) do
        (version_core >> any.absent?).absent? >>
          match["^/:"].repeat(1).as(:release)
      end

      # Three-part version, kept as a string.
      rule(:version_core) do
        digits >> str(".") >> digits >> str(".") >> digits
      end
      rule(:version) { version_core.as(:version) }

      rule(:identifier) do
        publisher_prefix.maybe >>
          type >> space >>
          number_core >> suffix.maybe >> parts >>
          (str(":") >> release).maybe >>
          (str("/") >> version).maybe
      end

      rule(:root) { identifier }

      def self.parse(input)
        new.parse(input)
      end
    end
  end
end
