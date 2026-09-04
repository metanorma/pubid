# frozen_string_literal: true

module Pubid
  module Renderers
    class HumanReadable < Base
      # `**_opts` absorbs render flags that only some flavors honour (e.g. the
      # IEEE-specific `:trademark`), so the shared renderer tolerates them.
      def render(context:, with_edition: false, **_opts)
        parts = []
        parts << render_publisher_and_stage(context)
        parts << render_number_portion(context)
        parts << render_edition_portion(context) if with_edition
        result = parts.compact.join(" ")
        result << render_language_portion(context, with_edition: with_edition)
        result << " (all parts)" if @id.all_parts
        result
      end

      private

      def render_publisher_and_stage(context)
        ann = context.annotated
        if @id.publisher
          pub_str = annotate(@id.publisher.render(context:), "publisher",
                             annotated: ann)
        end
        stage_str = @id.typed_stage.render(context:) if @id.typed_stage

        if stage_str && !stage_str.empty?
          has_copub = @id.publisher&.copublished?
          sep = has_copub ? " " : "/"
          stage_str = annotate(stage_str, typed_stage_css(@id.typed_stage),
                               annotated: ann)
          "#{pub_str}#{sep}#{stage_str}"
        else
          pub_str
        end
      end

      def render_number_portion(context)
        ann = context.annotated
        parts = []
        if @id.number
          parts << annotate(render_component(@id.number, context), "docnumber",
                            annotated: ann)
        end
        if @id.part
          parts << "-#{annotate(render_component(@id.part, context), 'part', 
                                annotated: ann)}"
        end
        if @id.subpart
          parts << "-#{annotate(render_component(@id.subpart, context), 'part', 
                                annotated: ann)}"
        end
        if @id.stage_iteration
          parts << ".#{annotate(@id.stage_iteration.render(context:), 
                                'iteration', annotated: ann)}"
        end
        date_str = @id.date.render(context:) if @id.date && context.with_date
        parts << ":#{annotate(date_str, 'year', annotated: ann)}" if date_str
        parts.join
      end

      def render_edition_portion(context)
        return unless @id.edition&.number

        annotate(@id.edition.render(context:), "edition",
                 annotated: context.annotated)
      end

      def render_language_portion(context, with_edition: false)
        return "" unless @id.languages&.any? && context.with_language_code != :none

        use_single = with_edition ? false : context.with_language_code == :single
        rendered = @id.languages.map do |l|
          annotate(l.render(context:, lang_single: use_single), "language",
                   annotated: context.annotated)
        end
        "(#{rendered.join(use_single ? '/' : ',')})"
      end
    end
  end
end
