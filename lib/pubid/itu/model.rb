require "lutaml/model"
# frozen_string_literal: true

module Pubid
  module Itu
    class Model < Lutaml::Model::Serializable
      attribute :sector, :string
      attribute :series, :string
      attribute :number, :string
      attribute :subseries, :string
      attribute :part, :string
      attribute :supplement, :string
      attribute :amendment, :string
      attribute :annex, :string
      attribute :corrigendum, :string
      attribute :addendum, :string
      attribute :appendix, :string
      attribute :month, :string
      attribute :year, :string
      attribute :second_number, :string
      attribute :range, :string
      attribute :sg_number, :string

      def to_s
        parts = []

        # Add publisher and sector
        parts << "ITU-#{sector}" if sector

        # Add series (handle special cases)
        if series == "OB"
          # Operational Bulletin
          parts << "#{series} No. #{number}"
        elsif series&.start_with?("SG")
          # Study Group Question
          parts << "#{series}.#{number}"
          parts[-1] << "-#{part}" if part
        elsif series == "R" && !number
          # Resolution without number
          parts << "R.#{number}"
          parts[-1] << "-#{part}" if part
        elsif series
          # Regular series
          series_str = series.to_s
          if number
            series_str << ".#{number}"
            series_str << ".#{subseries}" if subseries
            series_str << "-#{part}" if part
          end
          parts << series_str

          # Add second number for combined standards
          if second_number.is_a?(Hash)
            second_str = "/#{second_number[:series]}.#{second_number[:number]}"
            second_str << ".#{second_number[:subseries]}" if second_number[:subseries]
            second_str << "-#{second_number[:part]}" if second_number[:part]
            parts[-1] << second_str
          end

          # Add range notation
          if range.is_a?(Hash)
            parts[-1] << "-#{range[:series]}.#{range[:number]}"
          end
        elsif number && !series
          # Handbook or similar (just number)
          parts << number
          parts[-1] << "-#{part}" if part
        end

        # Add supplement
        if supplement
          parts << "Suppl. #{supplement}"
        end

        # Add annex
        if annex
          parts << "Annex #{annex}"
        end

        # Add date
        if month && year
          parts << "(#{month.rjust(2, '0')}/#{year})"
        elsif year
          parts << "(#{year})"
        end

        # Add amendment
        if amendment
          parts << "Amd. #{amendment}"
        end

        # Add corrigendum
        if corrigendum
          parts << "Cor. #{corrigendum}"
        end

        # Add addendum
        if addendum
          parts << "Add. #{addendum}"
        end

        # Add appendix
        if appendix
          parts << "App. #{appendix}"
        end

        parts.join(" ")
      end
    end
  end
end
