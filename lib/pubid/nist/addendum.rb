
module Pubid::Nist
  class Addendum < Identifier
    def_delegators 'Pubid::Nist::Addendum', :type

    attr_accessor :base

    def initialize(base:, number: nil)
      @number = number
      @base = base
    end

    def self.type
      { key: :add, title: "Addendum" }
    end

    def self.get_renderer_class
      Renderer::Addendum
    end
  end
end
