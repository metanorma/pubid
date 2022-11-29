module Pubid::Iso::Renderer
  class Tc < Base

    def render_identifier(params, opts)
      "%{publisher} %{tctype} %{tcnumber}%{sctype}%{wgtype} N%{number}" % params
    end

    def render_tctype(tctype, _opts, _params)
      tctype.is_a?(Array) && tctype.join("/") || tctype.to_s
    end

    # TC 184/SC/WG 4 - no wg number
    # TC 184/SC 4/WG 12 - separate sc and wg number
    def render_sctype(sctype, _opts, params)
      if params[:wgnumber] || !params[:wgtype]
        "/#{sctype} #{params[:scnumber]}"
      else
        "/#{sctype}"
      end
    end

    def render_wgtype(wgtype, _opts, params)
      if params[:wgnumber]
        "/#{wgtype} #{params[:wgnumber]}"
      else
        "/#{wgtype} #{params[:scnumber]}"
      end
    end
  end
end
