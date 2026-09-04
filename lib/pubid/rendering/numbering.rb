# frozen_string_literal: true

module Pubid
  module Rendering
    module Numbering
      # Render number with optional parts and subparts
      # @param number [Components::Code, String, nil] primary number
      # @param part [Components::Code, String, nil] optional part
      # @param subpart [Components::Code, String, nil] optional subpart
      # @param options [Hash] rendering options
      # @return [String] formatted numbering string
      def render_numbering(number, part = nil, subpart = nil, **options)
        number_str = numbering_value(number)
        return "" unless number_str

        result = " #{number_str}"
        separator = options[:part_separator] || "-"
        [part, subpart].each do |component|
          value = numbering_value(component)
          result += "#{separator}#{value}" if value
        end

        result
      end

      private

      # `number`/`part`/`subpart` are a Components::Code on ::Pubid::Identifier
      # but a plain :string in a growing number of flavors, so read the value
      # through whichever shape the caller holds. Returns nil for an absent or
      # empty component, which is what suppresses the segment.
      def numbering_value(component)
        return nil if component.nil?

        value = component.respond_to?(:value) ? component.value : component
        return nil if value.nil? || value.to_s.empty?

        value.to_s
      end
    end
  end
end
