module Pubid::Iso::Renderer
  class UrnTc < Pubid::Core::Renderer::Urn

    def render_identifier(params)
      "urn:iso:doc:%{publisher}%{copublisher}:%{tctype}:%{tcnumber}%{sctype}%{wgtype}:%{number}" % params
    end

    def render_tctype(tctype, _opts, _params)
      (tctype.is_a?(Array) && tctype.join(":") || tctype).downcase
    end

    def render_sctype(sctype, _opts, params)
      ":#{sctype.downcase}:#{params[:scnumber]}"
    end

    def render_wgtype(wgtype, _opts, params)
      if params[:wgnumber]
        ":#{wgtype.downcase}:#{params[:wgnumber]}"
      else
        ":#{wgtype.downcase}"
      end
    end
  end
end
