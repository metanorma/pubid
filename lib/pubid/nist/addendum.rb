
module Pubid::Nist
  class Addendum < Identifier
    def_delegators 'Pubid::Nist::Identifier::Addendum', :type

    attr_accessor :base

    def initialize(base:, number: nil)
      @number = number
      @base = base
    end

    def self.type
      { key: :add, title: "Addendum" }
    end

    def to_h(deep: true)
      super.merge(type: "Add")
    end

    def self.get_renderer_class
      Renderer::Addendum
    end
  end
end
