# frozen_string_literal: true

module Pubid
  module Idf
    # Human-readable renderer for IDF identifiers.
    #
    # Produces strings like:
    #   "IDF 125:1988"
    #   "IDF/AMD 1:2023"
    #   "IDF 125:1988/AMD 1:2023"
    #
    # The renderer is registered as the `:human` format in the IDF format
    # registry and invoked via `render(format: :human)`.
    class Renderer < ::Pubid::Renderers::Base
      def render(context: nil, **opts)
        id = @id

        case id
        when SupplementIdentifier
          render_supplement(id, opts, context)
        else
          render_single(id, opts, context)
        end
      end

      private

      def render_single(id, opts, context)
        [
          publisher_portion(id, context),
          number_portion(id, opts, context),
        ].join
      end

      def publisher_portion(id, context)
        [
          id.publisher.render(context:),
          (id.typed_stage.abbreviation.empty? ? "" : "/#{id.typed_stage.abbreviation}"),
        ].join
      end

      def number_portion(id, opts, context)
        lang_single = opts[:lang_single] || false

        [
          (id.number ? " #{id.number}" : ""),
          (id.part ? "-#{id.part}" : ""),
          (id.subpart ? "-#{id.subpart}" : ""),
          (id.stage_iteration ? ".#{id.stage_iteration.render(context:)}" : ""),
          (id.date ? ":#{id.date.render(context:)}" : ""),
          language_portion(id, lang_single: lang_single),
        ].join
      end

      def language_portion(id, lang_single: false)
        return "" unless id.languages&.any?

        [
          "(",
          id.languages.map do |lang|
            lang.to_s(lang_single: lang_single)
          end.join(lang_single ? "/" : ","),
          ")",
        ].join
      end

      def render_supplement(id, opts, context)
        lang = opts[:lang] || :en
        lang_single = opts[:lang_single] || false
        with_edition = opts[:with_edition] || false

        [
          id.base.to_s(lang: lang, lang_single: lang_single,
                                   with_edition: with_edition),
          "/",
          id.typed_stage.abbreviation,
          " ",
          id.number,
          (id.date ? ":#{id.date.render(context:)}" : ""),
        ].join
      end
    end
  end
end
