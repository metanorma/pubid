# frozen_string_literal: true

module Pubid
  module W3c
    # Human-readable renderer for W3C identifiers.
    #
    # Produces strings like:
    #   "W3C WD-charmod-19991129"
    #   "W3C NOTE-xml-names"
    #   "W3C 2dcontext"
    #
    # Registered as the :human format in the W3C format registry and invoked via
    # `render(format: :human)`. When `id.with_publisher == false` the leading
    # "W3C " publisher token is dropped.
    class Renderer < ::Pubid::Renderers::Base
      PUBLISHER = "W3C"

      def render(context: nil, **opts)
        id = @id
        body = +""
        body << "#{id.type_prefix}-" if id.type_prefix
        body << id.number.to_s
        body << "-#{id.date}" if id.date

        with_publisher?(id) ? "#{PUBLISHER} #{body}" : body
      end

      private

      def with_publisher?(id)
        id.with_publisher != false
      end
    end
  end
end
