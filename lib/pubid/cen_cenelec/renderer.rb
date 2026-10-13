# frozen_string_literal: true

module Pubid
  module CenCenelec
    # Human-readable renderer for CEN/CENELEC identifiers.
    #
    # Produces strings like:
    #   "EN 196-3:2005"
    #   "EN ISO 8601:2019"
    #   "prEN 12345:2020"
    #   "CEN/TS 12345:2005"
    #   "EN 196-3:2005+A1:2008"
    #   "EN 60038/AC1:2012"
    #   "ENV ISO 8601"
    #
    # The renderer is registered as the +:human+ format in the CEN/CENELEC format
    # registry and invoked via +render(format: :human)+.
    class Renderer < ::Pubid::Renderers::Base
      def render(context: nil, **opts)
        id = @id
        @context = context

        case id
        when Identifiers::AdoptedEuropeanNorm
          render_adopted_european_norm(id)
        when Identifiers::Amendment
          render_amendment(id)
        when Identifiers::Corrigendum
          render_corrigendum(id)
        when Identifiers::ConsolidatedIdentifier
          render_consolidated(id)
        when Identifiers::Fragment
          render_fragment(id)
        when Identifiers::EuropeanPrestandard
          render_european_prestandard(id, **opts)
        when Identifiers::Base
          # CEN identifiers::Base hierarchy (Amendment, Corrigendum, etc. handled above)
          render_cen_base(id)
        when SingleIdentifier
          render_single(id)
        else
          render_single(id)
        end
      end

      private

      # SingleIdentifier (EN, Guide, TR, TS, CWA, HD, etc.):
      # Complex rendering with draft stages, copublishers, typed stages
      def render_single(id)
        parts = []

        # Check if we have a draft stage (prEN, FprEN) - these include both stage and type
        is_draft_stage = !draft_stage_abbr(id).nil?

        # Get type short name - for draft stages, extract base type
        type_short = if is_draft_stage
                       id.typed_stage.type_code.to_s.upcase # :en => "EN"
                     elsif id.type.is_a?(Components::Type)
                       id.type.abbr
                     elsif id.class.type.is_a?(Hash)
                       id.class.type[:short]
                     else
                       "EN" # Default
                     end

        # Track if we should use slash before type
        use_slash_before_type = false

        # CWA, HD, ES, CR and ENV act as the publisher (not EN)
        if CenCenelec::PUBLISHER_TYPES.include?(type_short)
          # Stage prefix OR type as publisher
          parts << if id.typed_stage&.abbr && id.typed_stage.abbr.first != type_short
                     id.typed_stage.abbr.first
                   else
                     type_short
                   end
        elsif is_draft_stage
          # Draft stage prefix (prEN, FprEN) OR regular publisher
          parts << id.typed_stage.abbr.first
        elsif id.publisher
          parts << id.publisher.render(context: @context)
          use_slash_before_type = true # When publisher present, use slash before type
        end

        # Copublishers - add to last part (publisher) with slash
        if id.copublishers&.any?
          copub_str = id.copublishers.map { |cp| cp.render(context: @context) }.join("/")
          unless copub_str.empty?
            if parts.any?
              parts[-1] = "#{parts[-1]}/#{copub_str}"
            else
              parts << copub_str
            end
          end
        end

        # Type for non-EN documents (TS, TR) - but not the publisher-types
        # or Guide
        if type_short != "EN" && type_short != "Guide" &&
            !CenCenelec::PUBLISHER_TYPES.include?(type_short)
          if use_slash_before_type && parts.any?
            # Use slash separator for publisher/type combination (TS, TR only)
            parts << "/#{type_short}"
          else
            parts << type_short
          end
        elsif type_short == "Guide"
          # Guide uses SPACE separator, not slash
          parts << "Guide"
        end

        # Number with part (which may be multi-level like "5-1-1") and the
        # ETSI-style version suffix ("EN 302 326-2 V2.2.1")
        if id.number
          number_str = id.number
          if id.part
            number_str += "-#{id.part}"
          end
          # the version capture carries its own leading space
          number_str += id.version if id.version
          parts << number_str
        end

        # Join parts - but handle slash prefix for type
        result = ""
        parts.each_with_index do |part, idx|
          if idx.positive? && !part.start_with?("/")
            result += " "
          end
          result += part
        end

        # Date
        if id.date
          year_val = id.date.is_a?(::Pubid::Components::Date) ? id.date.render(context: @context) : id.date.to_i
          result += ":#{year_val}"
        end

        result
      end

      # "prEN" or "FprEN" when +id+ has that draft stage, else nil. A draft
      # stage prints in place of the publisher.
      def draft_stage_abbr(id)
        abbr = id.typed_stage&.abbr&.first
        abbr if %w[prEN FprEN].include?(abbr)
      end

      # CEN Identifiers::Base: simple key-value model
      # Format: {PUBLISHER} NUMBER[-PART]:YEAR
      def render_cen_base(id)
        result = ""

        # Stage or Publisher
        if id.stage
          result += id.stage
        elsif id.publisher&.any?
          result += id.publisher.join("/")
        end

        # If we have adopted, render it (contains all info)
        if id.adopted
          result += " #{id.adopted}"
          # Don't add our own number/parts/year - they're in adopted
        else
          # Only render our own fields if no adoption
          # Type - use space for Guide, slash for TR/TS
          if id.type
            sep = id.type == "Guide" ? " " : "/"
            result += "#{sep}#{id.type}"
          end

          result += " #{id.number}"
          result += id.parts.map { |p| "-#{p}" }.join if id.parts&.any?
          result += ":#{id.year}" if id.year

          # Supplements
          if id.supplements&.any?
            id.supplements.each do |supp|
              sep = supp[:type] == :amendment ? "/" : "+"
              result += "#{sep}#{supp[:type] == :amendment ? 'A' : 'AC'}"
              result += supp[:number] if supp[:number] && !supp[:number].empty?
              result += ":#{supp[:year]}" if supp[:year]
            end
          end

          # Edition
          result += " ED#{id.edition}" if id.edition
        end

        result
      end

      # AdoptedEuropeanNorm: "EN ISO 8601:2019", "CEN/CLC ISO/IEC 17000",
      # "prEN ISO 1234:2020" (a draft stage prints in place of "EN")
      def render_adopted_european_norm(id)
        publishers = ([id.publisher] + Array(id.copublishers)).compact
          .map { |p| p.render(context: @context) }
        draft = draft_stage_abbr(id)
        publishers[0] = draft if draft
        result = publishers.join("/")
        result += " #{id.adopted}" if id.adopted
        result
      end

      # Amendment: "EN 196-3:2005/A1:2008"
      def render_amendment(id)
        "#{id.base}/#{supplement_token(id)}"
      end

      # Corrigendum: "EN 60038/AC1:2012", "EN 61375-2-3:2015/AC:2016-11"
      def render_corrigendum(id)
        "#{id.base}/#{supplement_token(id)}"
      end

      # ConsolidatedIdentifier: "EN 196-3:2005+A1:2008". The first member is
      # the base document; the others are supplements with no base.
      def render_consolidated(id)
        base, *supplements = id.identifiers
        base.to_s + supplements.map do |sub_id|
          if sub_id.is_a?(Identifiers::Amendment) ||
              sub_id.is_a?(Identifiers::Corrigendum)
            "+#{supplement_token(sub_id)}"
          else
            # Other identifiers (should not happen in typical bundles)
            "+#{sub_id}"
          end
        end.join
      end

      # The supplement without its base: "A1:2008", "AC1:2012",
      # "AC:2016-11" (an unnumbered corrigendum).
      def supplement_token(id)
        prefix = id.is_a?(Identifiers::Corrigendum) ? "AC" : "A"
        result = "#{prefix}#{id.number}"
        return result unless id.year

        result += ":#{id.year}"
        result += "-#{id.month}" if id.respond_to?(:month) && id.month
        result
      end

      # Fragment: "EN 60038 AMD1 FRAG2"
      def render_fragment(id)
        "#{id.base} FRAG#{id.number}"
      end

      # EuropeanPrestandard: "ENV ISO 8601" or falls through to SingleIdentifier
      def render_european_prestandard(id, **opts)
        if id.adopted
          "ENV #{id.adopted}"
        else
          render_single(id)
        end
      end
    end
  end
end
