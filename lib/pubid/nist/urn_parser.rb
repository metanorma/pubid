# frozen_string_literal: true

module Pubid
  module Nist
    # Parses NIST URNs back into identifiers.
    #
    # UrnGenerator emits:
    #   urn:nist:{type}:{code}[.{revision}].supp
    #
    # type is the lowercase series (sp, fips, ir, nistcir, …). code is the
    # alphanumeric designation. revision is `r{N}` when present. The `.supp`
    # suffix marks the series as supplementable.
    #
    # Examples:
    # - urn:nist:sp:800-53.supp        → NIST SP 800-53
    # - urn:nist:sp:800-53.r5.supp     → NIST SP 800-53r5
    # - urn:nist:fips:199.supp         → NIST FIPS 199
    class UrnParser < Pubid::UrnParser::Base
      TYPE_UPCASE = {
        "sp" => "SP",
        "fips" => "FIPS",
        "ir" => "IR",
        "nistcir" => "NISTCIR",
        "nbs" => "NBS",
        "nistir" => "NISTIR",
        "csf" => "CSF",
        "gcr" => "GCR",
        "itl" => "ITL",
        "jres" => "JRES",
        "lcirc" => "LCIRC",
        "mon" => "MONO",
        "ms" => "MS",
        "nsrds" => "NSRDS",
        "tn" => "TN",
        "wp" => "WP",
      }.freeze

      def parse_urn(urn)
        body = strip_namespace(urn)
        parts = split_parts(body)

        type_token, payload = parts
        code, suffix = parse_payload(payload)

        text = "#{publisher_for(type_token)} #{type_label(type_token)} #{code}"
        text += suffix
        flavor_parse(text)
      end

      private

      # The NBS-era series carry the NBS imprint in their canonical form
      # ("NBS CSM 1") — the rebuild must name the publisher the document
      # carries, or the flavor parse rejects its own URN's rebuild.
      NBS_SERIES = ["csm"].freeze

      def publisher_for(type_token)
        NBS_SERIES.include?(type_token.downcase) ? "NBS" : "NIST"
      end

      # The generator dot-joins the identity's fields after the number
      # ("urn:nist:circ:25.e1924.supp", "urn:nist:circ:539.v10.supp",
      # "urn:nist:circ:24.supp-1"). Reassemble the human spelling the
      # flavor parser reads: the edition and volume glue onto the number,
      # a revision glues after them, the bare ".supp" marks
      # supplementability (non-identity) and a valued ".supp-<v>" is the
      # supplement's "sup<v>" face.
      def parse_payload(payload)
        tokens = payload.split(".")
        code = tokens.shift.to_s
        suffix = +""
        part = nil
        edition = nil
        volume = nil
        revision = nil
        supplement = nil

        tokens.each do |token|
          case token
          when /\Ar\d+\z/i then revision = token
          when /\Ae[\w]+\z/i then edition = token
          when /\Av\d+\z/i then volume = token
          when /\Asupp-(.+)\z/im then supplement = Regexp.last_match(1)
          when "supp" then next # supplementability marker, not identity
          when "insert", "errata" then suffix << token # glued in the human
          when /\A[A-Z]\z/ then part = token # part letter, glued to the code
          when /\A[A-Z][a-z]+\d{4}\z/ # edition's additional text ("13e2.June1908")
            edition = "#{edition}.#{token}" if edition
          else suffix << ".#{token}" # unknown marker: keep verbatim
          end
        end

        code << part.to_s
        suffix << edition.to_s << volume.to_s << revision.to_s
        suffix << "sup#{supplement}" if supplement
        [code, suffix]
      end

      def type_label(token)
        TYPE_UPCASE.fetch(token.downcase) { token.upcase }
      end
    end
  end
end
