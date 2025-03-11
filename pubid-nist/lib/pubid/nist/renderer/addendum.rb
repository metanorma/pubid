require_relative "base"

module Pubid::Nist::Renderer
  class Addendum < Base
    def render_identifier(params, opts)
       # = "%{base}" % params
      result = params[:base].to_s(opts[:format])
      case opts[:format]
      when :long
        "Addendum to #{result}"
      when :abbrev
        "Add. to #{result}"
      when :short
        "#{result} Add."
      when :mr
        "#{result}.add-1"
      end
    end
  end
end
