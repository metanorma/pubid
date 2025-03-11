module Pubid::Iso::Renderer
  class Base < Pubid::Core::Renderer::Base
    attr_accessor :prerendered_params

    TRANSLATION = {
      russian: {
        publisher: { "ISO" => "ИСО", "IEC" => "МЭК" },
        stage: { "FDIS" => "ОПМС",
                 "DIS" => "ПМС",
                 "NP" => "НП",
                 "AWI" => "АВИ",
                 "CD" => "КПК",
                 "PD" => "ПД",
                 "FPD" => "ФПД" },
        type: { "TS" => "ТС",
                "TR" => "ТО",
                "ISP" => "ИСП" },
      },
      french: {
        publisher: { "IEC" => "CEI" },
      },
    }.freeze

    TYPE = "".freeze

    def render_base_identifier(**args)
      prerender(**args)

      render_identifier(@prerendered_params, args)
    end

    # Render identifier
    # @param with_edition [Boolean] include edition in output
    # @see Pubid::Core::Renderer::Base for another options
    def render(with_edition: true, with_language_code: :iso, with_date: true, **args)
      render_base_identifier(**args.merge({ with_date: with_date,
                                            with_language_code: with_language_code,
                                            with_edition: with_edition })) +
        @prerendered_params[:language].to_s
    end

    def render_base(_base, _opts, _params)
    end

    def render_type_prefix(params, opts)
      result = params[:stage].nil? || !params[:stage].is_a?(Pubid::Core::TypedStage) ? self.class::TYPE : ""

      if params[:stage] != "" && !params[:stage].to_s(with_prf: opts[:with_prf]).empty? && !result.empty?
        " #{result}"
      else
        result
      end
    end

    def render_identifier(params, opts)
      stage = params.key?(:stage) ? postrender_stage(params[:stage], opts, params) : ""
      "%{publisher}#{stage}#{render_type_prefix(params, opts)} %{number}%{part}%{iteration}%{year}%{amendments}%{corrigendums}%{addendum}%{edition}" % params
    end

    def render_copublisher_string(publisher, copublishers, opts)
      case copublishers
      when String
        if opts[:language]
          copublishers = TRANSLATION[opts[:language]][:publisher][copublishers] || copublishers
        end
        [publisher, copublishers].join("/")
      when Array
        ([publisher] + copublishers.map(&:to_s)).map do |pub|
          if opts[:language]
            (TRANSLATION[opts[:language]][:publisher][pub] || pub).gsub('-', '/')
          else
            pub
          end
        end.join("/")
      else
        raise StandardError.new("copublisher must be a string or an array")
      end
    end

    def omit_post_publisher_symbol?(typed_stage, stage, opts)
      # return false unless typed_stage

      (stage.nil? || stage.empty_abbr?(with_prf: opts[:with_prf])) && typed_stage.nil?
    end

    def render_publisher(publisher, opts, params)

      if opts[:language]
        publisher = TRANSLATION[opts[:language]][:publisher][publisher] || publisher
      end
      # No copublishers
      unless params[:copublisher]

        # No copublisher and IS
        # ISO xxx
        if omit_post_publisher_symbol?(params[:typed_stage], params[:stage], opts)
          return publisher
        end

        # No copublisher and not IS
        # ISO/TR xxx
        return "#{publisher}/"
      end

      publisher_string = render_copublisher_string(publisher, params[:copublisher], opts)
      publisher_string.sub!("/IEC", "/CEI") if opts[:language] == :french

      # With copublisher and IS
      # ISO/IEC xxx
      if omit_post_publisher_symbol?(params[:typed_stage], params[:stage], opts)
        return publisher_string
      end

      # With copublisher but not IS
      # ISO/IEC TR xxx
      publisher_string + " "
    end

    def render_typed_stage(typed_stage, opts, params)
      return nil if typed_stage.to_s.empty?

      if opts[:language]
        return TRANSLATION[opts[:language]][:stage][typed_stage.to_s] || typed_stage.to_s
      end

      typed_stage.to_s
    end

    def render_stage(stage, _opts, _params)
      stage
    end

    def postrender_stage(stage, opts, params)
      return if stage.empty_abbr?(with_prf: opts[:with_prf])

      if opts[:language]
        return TRANSLATION[opts[:language]][:stage][stage.to_s(with_prf: opts[:with_prf])] ||
          stage.to_s(with_prf: opts[:with_prf])
      end

      stage.to_s(with_prf: opts[:with_prf])
    end

    def render_edition(edition, opts, _params)
      " ED#{edition}" if opts[:with_edition]
    end

    def render_iteration(iteration, _opts, _params)
      ".#{iteration}"
    end

    def render_language(language, opts, _params)
      return if opts[:with_language_code] == :none
      super
    end

    def render_year(year, opts, params)
      return ":#{year}" if params[:amendments] || params[:corrigendums]
      opts[:with_date] && ":#{year}" || ""
    end

    def render_part(part, opts, _params)
      "-#{part}"
    end

    def render_addendum(addendum, _opts, _params)
      if addendum[:year]
        "/Add #{addendum[:number]}:#{addendum[:year]}"
      else
        "/Add #{addendum[:number]}"
      end
    end
  end
end
