# frozen_string_literal: true

module Pubid
  module Renderers
    class Base
      def initialize(identifier)
        @id = identifier
      end

      def render
        raise NotImplementedError, "#{self.class}#render not implemented"
      end

      def self.render(identifier)
        new(identifier).render
      end

      # Partitions a value into (leading separators, core, trailing separators)
      # so "- : / space , ." stay OUTSIDE the annotation span (v1 parity).
      SEMANTIC_SPLIT = %r{\A([-:/ ,.]*)(.*?)([-:/ ,.]*)\z}m

      # type_code (a string) → semantic CSS class for the typed-stage token.
      # Anything not listed (and not the default "is") renders as "doctype".
      TYPED_STAGE_CSS = {
        "amd" => "amendment",
        "cor" => "corrigendum",
        "add" => "addendum",
      }.freeze

      private

      # Wrap a rendered value in a <span class="css_class"> when annotation is
      # enabled, keeping leading/trailing separator chars outside the span.
      def annotate(value, css_class, annotated:)
        str = value.to_s
        return value unless annotated && css_class && !str.empty?

        lead, core, trail = str.match(SEMANTIC_SPLIT).captures
        return value if core.empty?

        %(#{lead}<span class="#{css_class}">#{core}</span>#{trail})
      end

      # Render a value that may be a component or a bare scalar.
      #
      # `number`, `part` and `subpart` are `Components::Code` on
      # ::Pubid::Identifier but a plain `:string` in a growing number of
      # flavors, so a shared renderer cannot assume the format-aware
      # `#render(context:)` seam is there. This keeps both shapes working while
      # the flavors convert one tranche at a time.
      def render_component(value, context)
        return nil if value.nil?

        value.respond_to?(:render) ? value.render(context: context) : value.to_s
      end

      # Choose between "stage" and a type/supplement class for a typed stage.
      def typed_stage_css(typed_stage)
        code = typed_stage&.type_code.to_s
        return "stage" if code.empty? || code == "is"

        TYPED_STAGE_CSS[code] || "doctype"
      end
    end
  end
end
