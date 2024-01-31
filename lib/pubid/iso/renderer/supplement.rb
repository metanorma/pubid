require_relative "base"

module Pubid::Iso::Renderer
  class Supplement < Base
    TYPE = "Suppl".freeze

    # Render identifier
    # @param with_edition [Boolean] include edition in output
    # @see Pubid::Core::Renderer::Base for another options
    def render(with_edition: true, with_language_code: :iso, with_date: true, **args)
      @params[:base].to_s(lang: args[:language], with_edition: with_edition) +
        super(
          with_edition: with_edition, with_language_code: with_language_code, with_date: with_date,
          base_type: @params[:base].type[:key],
          **args
        ) +
        if @params[:base].language
          render_language(@params[:base].language,
                          { with_language_code: with_language_code }, nil).to_s
        else
          ""
        end
    end

    def render_identifier(params, opts)
      type_prefix = params[:stage].nil? || !params[:stage].is_a?(Pubid::Core::TypedStage) ? self.class::TYPE : ""

      stage = params[:stage]

      if params[:stage].instance_of?(Pubid::Core::Stage) && !params[:stage].to_s(with_prf: opts[:with_prf]).empty?
        type_prefix = " #{type_prefix}"
        stage = params[:stage].to_s(with_prf: opts[:with_prf])
      end

      if self.class == Supplement
        if opts[:base_type] == :dir
          "%{stage}%{publisher} SUP%{number}%{part}%{iteration}%{year}%{month}%{edition}" % params
        else
          "/#{stage}#{type_prefix}%{number}%{part}%{iteration}%{year}%{edition}" % params
        end
      else
        "/#{stage}#{type_prefix}%{number}%{part}%{iteration}%{year}%{edition}" % params
      end
    end

    def render_number(number, opts, _params)
      space = opts[:language] == :french ? "." : " "

      "#{space}#{number}"
    end

    def render_stage(stage, opts, params)
      # do not render stage when already has typed stage
      stage unless params[:typed_stage]
    end

    def render_publisher(publisher, opts, params)
      " #{publisher}" unless publisher.empty?
    end

    def render_edition(edition, opts, _params)
      " Edition #{edition}" if opts[:with_edition]
    end

    def render_month(month, _opts, _params)
      "-#{month}"
    end
  end
end
