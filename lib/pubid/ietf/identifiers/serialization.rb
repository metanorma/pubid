# frozen_string_literal: true

module Pubid
  module Ietf
    module Identifiers
      # Installs the flat, index-friendly attribute set and the shared
      # `key_value` block on the five concrete IETF leaves (Rfc, Bcp, Std, Fyi,
      # InternetDraft).
      #
      # Why the leaves and not the shared Pubid::Ietf::Identifier base:
      # `number` redefines the parent ::Pubid::Identifier's
      # `attribute :number, Components::Code` as a plain :string. Declaring that
      # on a class the concrete types INHERIT from resolves against the parent
      # definition nondeterministically under multi-flavor load — it passes an
      # IETF-only run and can flip `root.number` to "" under the full suite (the
      # IEEE lesson; see lib/pubid/ieee/identifiers/code_number.rb and
      # CLAUDE.md). Declaring `number` directly on each leaf removes the
      # ambiguity at the point of use.
      #
      # This matters because relaton-index bsearches on `id.root.number.to_s`,
      # and every IETF identifier is its own root (the flavor has no wrapper or
      # supplement types), so an empty key silently defeats the search for every
      # row. spec/pubid/ietf/root_number_spec.rb guards it and must run under
      # the FULL suite to be meaningful.
      #
      # `series` is deliberately NOT an attribute here: `_type` already encodes
      # it, so storing it would duplicate the type in every sub-series row. The
      # three sub-series leaves expose it as a derived reader instead.
      module Serialization
        def self.included(base)
          # Document number of an RFC or sub-series id ("2119", "66"), kept as
          # a string so the printed form carries no zero-pad; for an
          # Internet-Draft, the version-less slug INCLUDING the leading
          # "draft-" ("draft-ietf-quic-transport"). The slug is the right index
          # key for the same reason the number is for an RFC: a draft's
          # unversioned aggregator row and every one of its versions share it,
          # so a document and its variants cluster into one bucket.
          base.attribute :number, :string

          # Only these keys serialize; the inherited Pubid::Identifier
          # attributes are intentionally dropped. InternetDraft merges its own
          # `version` mapping on top of this block.
          base.key_value do
            map "_type", to: :_type, polymorphic_map: Identifier::IETF_TYPE_MAP
            map "number", to: :number
          end
        end
      end
    end
  end
end
