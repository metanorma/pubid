module Pubid::Iec::Renderer
  class TrfUrn < Urn

    def render_identifier(params)
      # Trailing ":" is the (always-empty) language slot; TRF URNs carry no
      # language. Previously this colon came from the base #render appending
      # ":#{lang}", which no longer runs (language is now a positional slot in
      # the base render_identifier, which TrfUrn overrides).
      "urn:iec:std:%{publisher}%{copublisher}:trf%{trf_publisher}:%{number}"\
      "%{part}%{conjuction_part}%{year}%{vap}"\
      "%{version}%{part_version}"\
      "%{trf_version}:" % params
    end

    def render_trf_version(trf_version, _opts, _params)
      ":v#{trf_version}" unless trf_version.empty?
    end

    def render_trf_publisher(trf_publisher, _opts, _params)
      ":#{trf_publisher.downcase}"
    end
  end
end
