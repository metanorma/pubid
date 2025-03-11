require_relative "../renderer/data"

module Pubid::Iso
  module Identifier
    class Data < Base
      def_delegators 'Pubid::Iso::Identifier::Data', :type

      def self.type
        { key: :data, title: "Data", short: "DATA" }
      end

      def self.get_renderer_class
        Renderer::Data
      end
    end
  end
end
