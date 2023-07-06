module Pubid::Itu::Renderer
  class Amendment < Pubid::Core::Renderer::Base
    # def render(**args)
    #   render_base_identifier(**args) + @prerendered_params[:language].to_s
    # end

    def render_identifier(params)
      "Amd %{number}" % params
    end
  end
end
