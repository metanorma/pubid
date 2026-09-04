# frozen_string_literal: true

module Pubid
  module Renderers
    class DirectivesRenderer < HumanReadable
      def render(context:, with_edition: false)
        parts = []
        parts << render_publisher_portion(context)
        num_port = render_number_portion(context)

        if num_port && !num_port.empty?
          if num_port.start_with?(":")
            result = parts.compact.join(" ") + num_port
          else
            parts << num_port
            result = parts.compact.join(" ")
          end
        else
          result = parts.compact.join(" ")
        end

        result << " #{render_edition_portion(context)}" if with_edition && @id.edition&.number
        result << render_language_portion(context, with_edition: with_edition)
        result
      end

      private

      def render_publisher_portion(context)
        ann = context.annotated
        if @id.publisher
          pub_str = annotate(@id.publisher.render(context:), "publisher",
                             annotated: ann)
        end
        abbr = @id.typed_stage ? @id.typed_stage.abbreviation(format_long: false) : ""
        unless abbr.empty?
          abbr = annotate(abbr, typed_stage_css(@id.typed_stage), 
                          annotated: ann)
        end
        subgroup_str = @id.subgroup.render(context:) if @id.subgroup

        [
          pub_str,
          (subgroup_str ? " #{subgroup_str}" : ""),
          (abbr.empty? ? "" : " #{abbr}"),
        ].join
      end

      def render_number_portion(context)
        ann = context.annotated
        parts = []
        if @id.number
          parts << annotate(render_component(@id.number, context), "docnumber",
                            annotated: ann)
        end
        if @id.part
          parts << " #{annotate(render_component(@id.part, context), 'part', 
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
        result = parts.join.strip
        result.empty? ? nil : result
      end
    end
  end
end
