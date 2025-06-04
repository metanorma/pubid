require_relative "urn"

module Pubid::Iso::Renderer
  class UrnTc < Urn
    def render_identifier(params)
      "urn:iso:doc:%<publisher>s%<copublisher>s:%<tctype>s:%<tcnumber>s" \
      "%<sctype>s%<wgtype>s:%<number>s%<all_parts>s" % params
    end

    def render_tctype(tctype, _opts, _params)
      (tctype.is_a?(Array) && tctype.join(":") || tctype.to_s).downcase
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
