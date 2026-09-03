# frozen_string_literal: true

module Pubid
  module Ashrae
    # Human-readable renderer for ASHRAE identifiers.
    #
    # Produces strings like:
    #   "ASHRAE Standard 15-2024"
    #   "ASHRAE Guideline 0-2019"
    #   "ASHRAE Addendum a to Standard 15-2001"
    #   "ASHRAE Standard 52.2-1999: Addenda Supplement Package"
    #   "ASHRAE Addenda c and d to Standard 15-1994"
    #   "ASHRAE Guideline 0-2005 Errata (September 28, 2011)"
    #   "Interpretations for Standard 15.2-2022"
    #
    # The renderer is registered as the +:human+ format in the ASHRAE format
    # registry and invoked via +render(format: :human)+.
    class Renderer < ::Pubid::Renderers::Base
      def render(context: nil, **_opts)
        id = @id

        case id
        when Identifiers::Addendum
          render_addendum(id)
        when Identifiers::AddendaPackage
          render_addenda_package(id)
        when Identifiers::CombinedAddenda
          render_combined_addenda(id)
        when Identifiers::Errata
          render_errata(id)
        when Identifiers::Interpretation
          render_interpretation(id)
        when SingleIdentifier
          render_single(id)
        else
          render_single(id)
        end
      end

      private

      # SingleIdentifier (Standard, Guideline): "ASHRAE Standard 15-2024"
      def render_single(id)
        parts = []
        parts << id.publisher if id.publisher
        parts << id.type.to_s if id.type
        result = parts.join(" ")
        result += " " if result.length.positive?
        result += id.number.to_s
        result += "-#{id.year}" if id.year
        result += " (#{id.amendment})" if id.amendment
        result += id.suffix if id.suffix
        result += " (RA#{id.reaffirmed})" if id.reaffirmed
        result
      end

      # Addendum: "ASHRAE Addendum a to Standard 15-2001"
      def render_addendum(id)
        return id.base.to_s unless id.base

        base_type = id.base.type || "Standard"

        if id.copublisher
          "#{id.copublisher} Addendum #{id.addendum_code} to #{id.base}"
        else
          result = "ASHRAE Addendum #{id.addendum_code} to #{base_type} #{id.base.number}"
          result += "-#{id.base.year}" if id.base.year
          result
        end.tap { |r| r << " (#{id.addendum_date})" if id.addendum_date }
      end

      # AddendaPackage: "ASHRAE Standard 52.2-1999: Addenda Supplement Package"
      def render_addenda_package(id)
        return id.base.to_s unless id.base

        result = "ASHRAE #{id.base.type || 'Standard'} #{id.base.number}"
        result += "-#{id.base.year}" if id.base.year
        result += ": Addenda #{id.package_description}" if id.package_description
        result
      end

      # CombinedAddenda: "ASHRAE Addenda c and d to Standard 15-1994"
      def render_combined_addenda(id)
        return id.base.to_s unless id.base

        base_type = id.base.type || "Standard"
        if id.addendum_codes
          result = "ASHRAE Addenda #{id.addendum_codes} to #{base_type} #{id.base.number}"
        else
          result = "ASHRAE Addenda to #{base_type} #{id.base.number}"
        end
        result += "-#{id.base.year}" if id.base.year
        result
      end

      # Errata: "ASHRAE Guideline 0-2005 Errata (September 28, 2011)"
      def render_errata(id)
        return id.base.to_s unless id.base

        result = id.base.to_s
        result += " Errata"
        result += " (#{id.errata_date})" if id.errata_date
        result
      end

      # Interpretation: "Interpretations for Standard 15.2-2022"
      def render_interpretation(id)
        return id.base.to_s unless id.base

        base_type = id.base.type || "Standard"
        result = "Interpretations for #{base_type} #{id.base.number}"
        result += "-#{id.base.year}" if id.base.year
        result
      end
    end
  end
end
