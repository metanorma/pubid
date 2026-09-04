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
        is_draft_stage = id.typed_stage&.abbr && %w[prEN
                                                     FprEN].include?(id.typed_stage.abbr.first)

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

        # For CWA/HD, they act as publisher (not EN)
        if %w[CWA HD CR].include?(type_short)
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

        # Type for non-EN documents (TS, TR) - but not CWA/HD or Guide
        if type_short != "EN" && !%w[CWA HD CR Guide].include?(type_short)
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

        # Number with part (which may be multi-level like "5-1-1")
        if id.number
          number_str = id.number
          if id.part
            number_str += "-#{id.part}"
          end
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

        # If we have adopted_identifier, render it (contains all info)
        if id.adopted_identifier
          result += " #{id.adopted_identifier}"
          # Don't add our own number/parts/year - they're in adopted_identifier
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

      # AdoptedEuropeanNorm: "EN ISO 8601:2019"
      def render_adopted_european_norm(id)
        result = id.publisher.is_a?(Array) ? id.publisher.join("/") : id.publisher.join("/")
        result += " #{id.adopted_identifier}" if id.adopted_identifier
        result
      end

      # Amendment: "EN 196-3:2005/A1:2008"
      def render_amendment(id)
        result = if id.base
                   "#{id.base}/A#{id.amendment_number}"
                 else
                   "/A#{id.amendment_number}"
                 end
        result += ":#{id.amendment_year}" if id.amendment_year
        result
      end

      # Corrigendum: "EN 60038/AC1:2012"
      def render_corrigendum(id)
        if id.base
          result = id.base.to_s
          result += "/AC"
          result += id.corrigendum_number if id.corrigendum_number && !id.corrigendum_number.empty?
        else
          result = "/AC#{id.corrigendum_number}"
        end
        if id.corrigendum_year
          result += ":#{id.corrigendum_year}"
          result += "-#{id.corrigendum_month}" if id.corrigendum_month && !id.corrigendum_month.empty?
        end
        result
      end

      # ConsolidatedIdentifier: "EN 196-3:2005+A1:2008"
      def render_consolidated(id)
        id.identifiers.map.with_index do |sub_id, idx|
          if idx.zero?
            # First identifier renders normally
            sub_id.to_s
          elsif sub_id.is_a?(Identifiers::Amendment)
            # Supplements render with "+" prefix (bundled/consolidated format)
            result = "+A#{sub_id.amendment_number}"
            result += ":#{sub_id.amendment_year}" if sub_id.amendment_year
            result
          # Only render the amendment portion, not the full id.to_s
          elsif sub_id.is_a?(Identifiers::Corrigendum)
            # Only render the corrigendum portion
            result = "+AC"
            result += sub_id.corrigendum_number if sub_id.corrigendum_number && !sub_id.corrigendum_number.empty?
            if sub_id.corrigendum_year
              result += ":#{sub_id.corrigendum_year}"
              result += "-#{sub_id.corrigendum_month}" if sub_id.corrigendum_month && !sub_id.corrigendum_month.empty?
            end
            result
          else
            # Other identifiers (should not happen in typical bundles) render with +
            "+#{sub_id}"
          end
        end.compact.join
      end

      # Fragment: "EN 60038 AMD1 FRAG2"
      def render_fragment(id)
        "#{id.base} FRAG#{id.fragment_number}"
      end

      # EuropeanPrestandard: "ENV ISO 8601" or falls through to SingleIdentifier
      def render_european_prestandard(id, **opts)
        if id.adopted_identifier
          "ENV #{id.adopted_identifier}"
        else
          render_single(id)
        end
      end
    end
  end
end
