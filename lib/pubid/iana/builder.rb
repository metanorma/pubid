# frozen_string_literal: true

module Pubid
  module Iana
    # Builds an IANA identifier object from a parse tree. There is a single
    # concrete type (Registry), so the builder just extracts the slug fields.
    class Builder
      def self.build(parsed_data)
        new.build(parsed_data)
      end

      def build(data)
        # The top-level slug is stored as `number` — it is the relaton-index
        # key; `Identifier#registry` reads it back.
        Identifiers::Registry.new(
          number: data[:registry].to_s,
          sub_registry: data[:sub_registry]&.to_s,
        )
      end
    end
  end
end
