require_relative "base"

module Pubid::Iso::Renderer
  class Extract < Supplement
    def render_identifier(params, opts)
      "/Ext%{number}%{year}" % params
    end
  end
end
