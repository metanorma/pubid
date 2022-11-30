module Pubid::Iso::Renderer
  class Supplement < Base
    # Render identifier
    # @param with_edition [Boolean] include edition in output
    # @see Pubid::Core::Renderer::Base for another options
    def render(with_edition: true, with_language_code: :iso, with_date: true, **args)
      @params[:base].to_s + super +
        if @params[:base].language
          render_language(@params[:base].language,
                          { with_language_code: with_language_code }, nil).to_s
        else
          ""
        end
    end

    def render_identifier(params, opts)
      space = opts[:language] == :french ? "." : " "
      type_prefix = params[:typed_stage].nil? || params[:typed_stage].empty? ? self.class::TYPE : ""

      type_prefix = " #{type_prefix}" if params[:stage].is_a?(Pubid::Iso::Stage) && !params[:stage].empty_abbr?

      "/%{typed_stage}%{stage}#{type_prefix}#{space}%{number}%{part}%{iteration}%{year}%{edition}" % params
    end

    def render_stage(stage, opts, params)
      # do not render stage when already has typed stage
      stage unless params[:typed_stage]
    end
  end
end
