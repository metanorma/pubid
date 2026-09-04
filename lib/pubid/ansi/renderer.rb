# frozen_string_literal: true

module Pubid
  module Ansi
    # Human-readable renderer for ANSI identifiers.
    #
    # Produces strings like:
    #   "ANSI X3.4"
    #   "ANSI/ISO 9899"
    #   "ANSI X9.8-1:2007"
    #
    # The renderer is registered as the `:human` format in the ANSI format
    # registry and invoked via `render(format: :human)`.
    class Renderer < ::Pubid::Renderers::Base
      def render(context: nil, **opts)
        id = @id

        parts = []
        parts << publisher_portion(id, context)
        parts << number_portion(id, context)
        result = parts.compact.join(" ")

        result << language_portion(id) if id.languages&.any?

        result
      end

      private

      def publisher_portion(id, context)
        if id.copublishers&.any?
          ([id.publisher] + id.copublishers).map { |p| p.render(context:) }.join("/")
        else
          id.publisher.render(context:)
        end
      end

      def number_portion(id, context)
        [
          id.number,
          (id.part ? "-#{id.part}" : ""),
          (id.date ? ":#{id.date.render(context:)}" : ""),
        ].join
      end

      def language_portion(id)
        return "" unless id.languages&.any?

        "(#{id.languages.map(&:code).join(',')})"
      end
    end
  end
end
