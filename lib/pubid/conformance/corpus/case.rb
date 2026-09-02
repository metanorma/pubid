# frozen_string_literal: true

module Pubid
  module Conformance
    module Corpus
      # Every proper rendering of the case's identifier.
      class Representations < Lutaml::Model::Serializable
        attribute :human, :string
        attribute :urn, :string
      end

      # One old spelling that must normalize to the human form.
      class Spelling < Lutaml::Model::Serializable
        attribute :spelling, :string
        attribute :style, :string
      end

      # Neutral rejection expectation - never an implementation class.
      class Error < Lutaml::Model::Serializable
        attribute :code, :string
      end

      class Expectation < Lutaml::Model::Serializable
        attribute :error, Error
      end

      # One corpus case (schema/test.schema.yaml is the wire contract).
      # `identifier` stays an opaque hash on purpose: it is the flavor's
      # own canonical to_hash carried as DATA to compare against, not a
      # structure the reader interprets.
      class Case < Lutaml::Model::Serializable
        attribute :id, :string
        attribute :style, :string
        attribute :identifier, :hash
        attribute :representations, Representations
        attribute :non_normalized_aliases, Spelling, collection: true,
                  default: -> { [] }
        attribute :roundtrip, :boolean
        attribute :expect, Expectation
        attribute :input, :string
        attribute :notes, :string
        attribute :review, :string

        def error_case? = !expect.nil? && !expect.error.nil?

        # Reference-bug debt: nothing to gate on.
        def quarantined? = identifier.nil? && !error_case?

        def review? = !review.to_s.empty?

        def roundtrip_failure_expected? = roundtrip == false
      end
    end
  end
end
