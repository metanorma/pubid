# frozen_string_literal: true

module Pubid
  module Ecma
    # Turns the Parslet parse tree into a concrete identifier object. The class
    # is chosen by which number key the parser captured.
    class Builder
      def self.build(parsed_data)
        new.build(parsed_data)
      end

      def build(data)
        klass, attrs =
          if data[:tr_number]
            [Identifiers::TechnicalReport, { number: data[:tr_number].to_s }]
          elsif data[:mem_number]
            [Identifiers::Memento, { number: data[:mem_number].to_s }]
          else
            [Identifiers::Standard, standard_attrs(data)]
          end

        klass.new(**attrs, **suffix_attrs(data))
      end

      private

      def standard_attrs(data)
        attrs = { number: data[:number].to_s }
        attrs[:part] = data[:part].to_s if data[:part]
        attrs
      end

      # ` ed<N>` / ` vol<N>` attach after the type alternation, so a technical
      # report and a memento carry them exactly as a standard does. An absent
      # suffix produces no parse key at all, so the attribute stays unset and
      # drops out of the canonical hash.
      def suffix_attrs(data)
        attrs = {}
        attrs[:edition] = data[:edition].to_s if data[:edition]
        attrs[:volume] = data[:volume].to_s if data[:volume]
        attrs
      end
    end
  end
end
