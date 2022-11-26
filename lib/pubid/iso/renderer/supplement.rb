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

    def render_identifier(params)
      type_prefix = params[:typed_stage].nil? || params[:typed_stage].empty? ? self.class::TYPE : ""

      type_prefix = " #{type_prefix}" if params[:stage] && !params[:stage].empty?

      "/%{typed_stage}%{stage}#{type_prefix} %{number}%{part}%{iteration}%{year}%{edition}" % params
    end
  end
end
