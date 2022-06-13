module Pubid::Core::Renderer
  class Base
    attr_accessor :params

    LANGUAGES = {
      "ru" => "R",
      "fr" => "F",
      "en" => "E",
      "ar" => "A",
    }.freeze

    def initialize(params)
      @params = params
    end

    def prerender_params(params, opts)
      params.map do |key, value|
        if respond_to?("render_#{key}")
          [key, send("render_#{key}", value, opts, params)]
        else
          [key, value]
        end
      end.to_h
    end

    # render from hash keys
    def render(with_date: true, with_language_code: :iso)
      params = prerender_params(@params,
                                { with_date: with_date, with_language_code: with_language_code })
      # render empty string when the key is not exist
      params.default = ""

      render_identifier(params)
    end

    def render_identifier(params)
      "%{publisher}%{copublisher}%{type}%{stage} %{number}%{part}%{iteration}"\
        "%{year}%{edition}%{amendments}%{corrigendums}%{language}" % params
    end

    def render_copublisher(copublisher, _opts, _params)
      # (!@copublisher.is_a?(Array) && [@copublisher]) || @copublisher
      if copublisher.is_a?(Array)
        copublisher.map(&:to_s).sort.map do |copublisher|
          "/#{copublisher.gsub('-', '/')}"
        end.join
      else
        "/#{copublisher}"
      end
    end

    def render_amendments(amendments, _opts, _params)
      amendments.sort.map(&:render_pubid).join("+")
    end

    def render_corrigendums(corrigendums, _opts, _params)
      corrigendums.sort.map(&:render_pubid).join("+")
    end

    def render_type(type, opts, params)
      if params[:copublisher]
        " #{type}"
      else
        "/#{type}"
      end
    end

    def render_stage(stage, opts, params)
      if params[:copublisher]
        " #{stage}"
      else
        "/#{stage}"
      end
    end

    def render_part(part, opts, _params)
      "-#{part}"
    end

    def render_year(year, opts, _params)
      opts[:with_date] && ":#{year}" || ""
    end

    def render_language(language, opts, _params)
      if opts[:with_language_code] == :single
        "(#{LANGUAGES[language]})"
      else
        "(#{language})"
      end
    end
    
    def render_edition(edition, _opts, _params)
      " ED#{edition}"
    end

    def render_iteration(iteration, _opts, _params)
      ".#{iteration}"
    end
  end
end
