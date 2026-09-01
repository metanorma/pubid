# frozen_string_literal: true

module Pubid
  module Etsi
    class Builder
      def self.build(parsed_data)
        new.build(parsed_data)
      end

      def build(data)
        # Check if supplements are present
        if data[:supplements]
          build_with_supplements(data)
        else
          build_etsi_standard(data)
        end
      end

      private

      def build_with_supplements(data)
        # Build base identifier first (without supplements)
        base_data = data.dup
        base_data.delete(:supplements)
        base = build_etsi_standard(base_data)

        # Process supplements - create supplement objects wrapping the base
        supplements_array = data[:supplements]
        supplements_array = [supplements_array] unless supplements_array.is_a?(Array)

        # Build supplements recursively - each wraps the previous
        supplements_array.reduce(base) do |current_base, supp|
          if supp[:amendment]
            Identifiers::Amendment.new(
              base: current_base,
              number: supp[:amendment][:number].to_i,
            )
          elsif supp[:corrigendum]
            Identifiers::Corrigendum.new(
              base: current_base,
              number: supp[:corrigendum][:number].to_i,
            )
          else
            current_base # Skip unknown supplement types
          end
        end
      end

      def build_etsi_standard(data)
        # Build components
        code = build_code(data)
        version = build_version(data)
        date = build_date(data)

        # The code fields are stored as flat index columns on the leaf (see
        # EtsiStandard) — `number` is what relaton-index keys on — so the Code
        # object built above is unpacked rather than assigned.
        Identifiers::EtsiStandard.new(
          type: data[:type].to_s,
          number: code.number,
          minor: code.minor,
          parts: code.parts || [],
          version: version,
          date: date,
        )
      end

      def build_code(data)
        number_data = data[:number]

        # Extract number string based on format
        number = if number_data.is_a?(Hash)
                   # Captured format
                   if number_data[:gsm_prefix]
                     # GSM with space: "GSM 11.14"
                     "GSM #{number_data[:main]}.#{number_data[:sub]}"
                   elsif number_data[:main] && number_data[:sub]
                     # Dotted format: "11.40"
                     "#{number_data[:main]}.#{number_data[:sub]}"
                   elsif number_data[:prefix1]
                     # Complex format: "ABC 123" or "ABC-DEF 123"
                     prefix = number_data[:prefix1].to_s
                     prefix += "-#{number_data[:prefix2]}" if number_data[:prefix2]
                     "#{prefix} #{number_data[:num]}"
                   else
                     # Simple with capture
                     number_data[:num].to_s
                   end
                 else
                   number_data.to_s
                 end

        parts = extract_parts(data[:parts])

        Components::Code.new(
          number: number,
          minor: data[:minor]&.to_s,
          parts: parts,
        )
      end

      def build_version(data)
        # Handle both version and edition. A partial reference omits both, in
        # which case version is left nil (not defaulted) so exclude/matches?
        # treat it as a wildcard.
        if data[:version]
          Components::Version.new(version: data[:version].to_s,
                                  is_edition: false)
        elsif data[:edition]
          Components::Version.new(version: data[:edition].to_s,
                                  is_edition: true)
        end
      end

      def build_date(data)
        # A partial reference omits the date; leave it nil rather than building
        # an empty Date, so the canonical to_hash drops it entirely.
        return nil unless data[:year]

        Pubid::Components::Date.new(
          year: data[:year].to_s,
          month: data[:month].to_s,
        )
      end

      def extract_parts(parts_data)
        return [] unless parts_data

        parts = []
        if parts_data.is_a?(Array)
          parts_data.each do |part_hash|
            parts << part_hash[:part].to_s if part_hash[:part]
          end
        elsif parts_data.is_a?(Hash) && parts_data[:part]
          parts << parts_data[:part].to_s
        end

        parts
      end
    end
  end
end
