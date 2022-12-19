require_relative "urn-supplement"

module Pubid::Iso::Renderer
  class UrnAmendment < UrnSupplement
    TYPE = "amd".freeze
  end
end
