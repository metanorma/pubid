# frozen_string_literal: true

module Pubid
  module Api
    # Human-readable renderer for API identifiers.
    #
    # Produces strings like:
    #   "API Std 650"
    #   "API MPMS CH 4.1"
    #   "API 5L-2018"
    #
    # The renderer is registered as the +:human+ format in the API format
    # registry and invoked via +render(format: :human)+.
    class Renderer < ::Pubid::Renderers::Base
      def render(context: nil, **opts)
        id = @id

        case id
        when Identifiers::Mpms
          render_mpms(id)
        when Identifiers::TypelessStandard
          render_typeless(id)
        else
          render_default(id)
        end
      end

      private

      def render_default(id)
        parts = ["API"]

        # Add type if available
        if id.class.attributes.key?(:type_string) && id.type_string
          parts << id.type_string
        end

        # Add code/number with part as one token
        parts << code_portion(id) if code_portion(id)

        result = parts.join(" ")
        result += "-#{id.year}" if id.year
        result += " (R#{id.reaffirmation})" if id.reaffirmation
        result
      end

      def render_mpms(id)
        parts = ["API", "MPMS"]

        # Add chapter
        parts << "CH #{id.number}" if id.number

        # Add section/subsection
        if id.section
          parts << ".#{id.section}"
          parts << ".#{id.subsection}" if id.subsection
        end

        # Add year
        parts << "-#{id.year}" if id.year

        parts.join(" ").gsub(" .", ".")
      end

      def render_typeless(id)
        parts = ["API"]

        # Add code/number
        parts << code_portion(id) if code_portion(id)

        # Add year
        parts << "-#{id.year}" if id.year

        # Add reaffirmation
        parts << " (R#{id.reaffirmation})" if id.reaffirmation

        parts.join(" ")
      end

      def code_portion(id)
        return nil unless id.code

        code_str = id.code.to_s
        code_str += "-#{id.part}" if id.part
        code_str
      end
    end
  end
end
