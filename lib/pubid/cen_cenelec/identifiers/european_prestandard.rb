# frozen_string_literal: true

require "lutaml/model"

module Pubid
  module CenCenelec
    module Identifiers
      class EuropeanPrestandard < SingleIdentifier
        attribute :type, Components::Type, default: -> { self.class.type[:key] }
        attribute :adopted_identifier, Pubid::Identifier, polymorphic: true

        TYPED_STAGES = [
          Components::TypedStage.new(
            code: :pubenv,
            stage_code: :published,
            type_code: :env,
            abbr: ["ENV"],
            name: "European Prestandard",
            harmonized_stages: %w[60.00 60.60],
          ),
        ].freeze

        def self.type
          { key: :env,
            web: :european_prestandard, title: "European Prestandard", short: "ENV" }
        end

        # An "ENV ISO 11079:1999" is a WRAPPER: the whole document identity
        # lives on the nested `adopted_identifier`, and this class carries no
        # number of its own, so `root.number` — the key relaton-index sorts and
        # bsearches on — was "". Walk to the adopted document instead.
        #
        # The chain reached further than this flavor: Bsi's
        # `AdoptedEuropeanNorm#number` delegates INTO this class, so a
        # "DD ENV ISO 11079:1999" keyed "" for the same reason.
        #
        # This is deliberately `#root` and not a `#number` method. `number` is a
        # lutaml attribute in this hierarchy, and a method of that name collides
        # with the generated accessor and corrupts attribute resolution
        # hierarchy-wide (the IEEE landmine in CLAUDE.md). `#root` is a plain
        # method on ::Pubid::Identifier, and walking a wrapper's member is its
        # documented shape — ConsolidatedIdentifier already walks
        # `identifiers.first.root`.
        def root
          adopted_identifier ? adopted_identifier.root : self
        end
      end
    end
  end
end
