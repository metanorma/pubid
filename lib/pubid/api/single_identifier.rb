# frozen_string_literal: true

module Pubid
  module Api
    class SingleIdentifier < Identifier
      # Generate URN for this identifier
      #
      # @return [String] URN representation

      # Stored as a plain string (always "API") so it round-trips through
      # to_hash/from_hash. Was a `def publisher` method, which made lutaml
      # serialize a String against the Components::Publisher attribute.
      attribute :publisher, :string, default: -> { "API" }

      # `number` and `part` are inherited as :string from
      # Pubid::Api::Identifier. There is deliberately no `code` attribute: one
      # existed here typed Components::Code, but nothing ever assigned it
      # (the parser emits no `:code` key), so it only misdirected
      # Renderer#code_portion away from the `number` the builder populates.
      attribute :year, :string
      attribute :reaffirmation, :string
    end
  end
end
