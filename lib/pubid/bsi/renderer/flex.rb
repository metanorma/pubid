require_relative "base"

module Pubid::Bsi::Renderer
  class Flex < Base

    TYPE = "Flex".freeze

    def render_identifier(params)
      suffix = "%{year}%{month}%{supplement}%{tracked_changes}%{translation}%{pdf}" % params

      "%{publisher} %{number}%{part}%{edition}#{suffix}" % params
    end

    def render_publisher(_publisher, _, _)
      "BSI #{TYPE}"
    end
  end
end
