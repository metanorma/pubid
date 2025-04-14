module Pubid::Ccsds::Renderer
  class Base < Pubid::Core::Renderer::Base
    TYPE = "".freeze

    def render_identifier(params)
      "%{publisher} %{series}%{number}%{part}%{book_color}%{edition}%{retired}" % params
    end

    def render_part(part, _opts, _params)
      ".#{part}"
    end

    def render_book_color(book_color, _opts, _params)
      "-#{book_color}"
    end

    def render_edition(edition, _opts, _params)
      "-#{edition}"
    end

    def render_retired(retired, _opts, _params)
      "-S" if retired
    end

    def render_language(language, opts, _params)
      " - #{language} Translated"
    end
  end
end
