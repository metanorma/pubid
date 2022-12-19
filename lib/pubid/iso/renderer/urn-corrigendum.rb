require_relative "urn-supplement"

module Pubid::Iso::Renderer
  class UrnCorrigendum < UrnSupplement
    TYPE = "cor".freeze
  end
end
