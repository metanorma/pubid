module Pubid::Iso::Renderer
  class Base < Pubid::Core::Renderer::Base
    attr_accessor :prerendered_params

    def render_supplement(supplement_params, **args)
      if supplement_params[:base].type == :amd
        # render inner amendment (cor -> amd -> base)
        render_supplement(supplement_params[:base].get_params, **args)
      else
        self.class.new(supplement_params[:base].get_params).render_base_identifier(
          # always render year for identifiers with supplement
          **args.merge({ with_date: true }),
          )
      end +
        case supplement_params[:typed_stage].type.type
        when :amd
          render_amendments(
            [Pubid::Iso::Amendment.new(**supplement_params.slice(:number, :year, :typed_stage, :edition, :iteration))],
            args,
            nil,
            )
        when :cor
          render_corrigendums(
            [Pubid::Iso::Corrigendum.new(**supplement_params.slice(:number, :year, :typed_stage, :edition, :iteration))],
            args,
            nil,
            )
          # copy parameters from Identifier only supported by Corrigendum
        end +
        (supplement_params[:base].language ? render_language(supplement_params[:base].language, args, nil) : "")
    end

    def render_base_identifier(**args)
      prerender(**args)

      render_identifier(@prerendered_params)
    end

    # Render identifier
    # @param with_edition [Boolean] include edition in output
    # @see Pubid::Core::Renderer::Base for another options
    def render(with_edition: true, with_language_code: :iso, with_date: true, **args)
      # super(**args.merge({ with_edition: with_edition }))
      # if %i(amd cor).include? @params[:typed_stage]&.type&.type
      #   render_supplement(@params, **args.merge({ with_date: with_date,
      #                                             with_language_code: with_language_code,
      #                                             with_edition: with_edition }))
      # else
        render_base_identifier(**args.merge({ with_date: with_date,
                                              with_language_code: with_language_code,
                                              with_edition: with_edition })) +
          @prerendered_params[:language].to_s
      # end

    end

    def render_identifier(params)
      "%{publisher}%{typed_stage}%{stage} %{number}%{part}%{iteration}%{year}%{amendments}%{corrigendums}%{edition}" % params
    end

    def render_copublisher_string(publisher, copublishers)
      case copublishers
      when String
        [publisher, copublishers].join("/")
      when Array
        ([publisher] + copublishers.map(&:to_s).sort).map do |pub|
          pub.gsub('-', '/')
        end.join("/")
      else
        raise StandardError.new("copublisher must be a string or an array")
      end
    end

    def omit_post_publisher_symbol?(typed_stage, stage, opts)
      # return false unless typed_stage

      (stage.nil? || stage.empty_abbr?(with_prf: opts[:with_prf])) && typed_stage.nil?
    end

    # @return [Boolean] returns false when there are no typed stage output to include
    # def omit_post_publisher_symbol?(typed_stage)
    #   return false unless typed_stage
    #
    #   (
    #     (
    #       typed_stage.typed_stage.nil? &&
    #       typed_stage.type.type == :is
    #     ) ||
    #     typed_stage.type.type == :dir
    #   ) &&
    #   (
    #     !typed_stage.stage ||
    #     (typed_stage.stage && typed_stage.stage.abbr.nil?)
    #   )
    # end

    def render_publisher(publisher, opts, params)

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

      publisher_string = render_copublisher_string(publisher, params[:copublisher])

      # With copublisher and IS
      # ISO/IEC xxx
      if omit_post_publisher_symbol?(params[:typed_stage], params[:stage], opts)
        return publisher_string
      end

      # With copublisher but not IS
      # ISO/IEC TR xxx
      publisher_string + " "
    end

    def render_typed_stage(typed_stage, _opts, params)
      return nil if typed_stage.to_s.empty?

      typed_stage.to_s
    end

    def render_stage(stage, opts, _params)
      return if stage.empty_abbr?(with_prf: opts[:with_prf])

      stage.to_s(with_prf: opts[:with_prf])
      # return if stage.nil? || (stage.abbr == "PRF" && !opts[:with_prf])
      #
      # stage.abbr
    end

    def render_edition(edition, opts, _params)
      " ED#{edition}" if opts[:with_edition]
    end

    def render_iteration(iteration, _opts, _params)
      ".#{iteration}"
    end

    def render_amendments(amendments, opts, _params)
      amendments.sort.map { |amendment| amendment.render_pubid(opts[:stage_format_long], opts[:with_date]) }.join("+")
    end

    def render_corrigendums(corrigendums, opts, _params)
      corrigendums.sort.map { |corrigendum| corrigendum.render_pubid(opts[:stage_format_long], opts[:with_date]) }.join("+")
    end

    def render_language(language, opts, _params)
      return if opts[:with_language_code] == :none
      super
    end

    def render_year(year, opts, params)
      return ":#{year}" if params[:amendments] || params[:corrigendums]
      opts[:with_date] && ":#{year}" || ""
    end
  end
end
