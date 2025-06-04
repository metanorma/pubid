require_relative "../renderer/addendum"

module Pubid::Iso
  module Identifier
    class Addendum < Supplement
      def_delegators 'Pubid::Iso::Identifier::Addendum', :type

      TYPED_STAGES = {
        dad: {
          abbr: "DAD",
          name: "Draft Addendum",
          harmonized_stages: %w[],
        },
      }.freeze
      def self.type
        { key: :add, title: "Addendum", short: "ADD" }
      end

      def self.get_renderer_class
        Renderer::Addendum
      end
    end
  end
end
