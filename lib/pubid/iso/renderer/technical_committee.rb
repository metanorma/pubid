require_relative "base"

module Pubid::Iso::Renderer
  class TechnicalCommittee < Base

    def omit_post_publisher_symbol?(_typed_stage, _stage, _opts)
      # always need post publisher symbol, because we always have to add "TR"
      false
    end

    def render_identifier(params, opts)
      if params[:wgnumber] && !params[:wgnumber].empty?
        "%{publisher}%{tctype} %{tcnumber}%{sctype}%{scnumber}%{wgtype}%{wgnumber} %{number}" % params
      else
        "%{publisher}%{tctype} %{tcnumber}%{sctype}%{wgtype}%{scnumber} %{number}" % params
      end
    end

    def render_tctype(tctype, _params, _opts)
      if tctype.is_a?(Array)
        tctype.join("/")
      else
        tctype
      end
    end

    def render_number(number, _params, _opts)
      "N#{number}"
    end

    def render_sctype(sctype, _params, _opts)
      "/#{sctype}"
    end

    def render_wgtype(wgtype, _params, _opts)
      "/#{wgtype}"
    end

    def render_wgnumber(wgnumber, _params, _opts)
      " #{wgnumber}"
    end

    def render_scnumber(scnumber, _params, _opts)
      " #{scnumber}"
    end
  end
end
