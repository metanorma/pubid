# frozen_string_literal: true

module Pubid
  module Ieee
    module Identifiers
      # Mixin for concrete IEEE leaf identifiers that are their own `#root` and
      # carry a document code. It splits the code into separate, index-friendly
      # scalar attributes and, crucially, **replaces** the serialized `code`
      # string with them:
      #
      #   number    :string             bare-digit narrowing key ("802", "37")
      #   prefix    :string             letter series designator ("C"), if any
      #   parts     :string collection  dotted/dashed parts (["16", "1"])
      #   separator :string             "." or "-", to render the parts back
      #
      # relaton's index-v2 keys its binary search on `id.root.number.to_s` and
      # narrows a part-less reference (`IEEE 802`) to the whole bucket of parts
      # (`802.11`, `802.16`, `802.16.1`), then matches `parts` — so `number`
      # (part-less) and `parts` MUST be separate columns. The full `code` string
      # is not serialized at all; `code_obj` (the runtime Components::Code the
      # renderer/urn_generator read) is rebuilt losslessly from the four fields.
      #
      # Why a leaf mixin and not the base: IEEE keeps identity in `code`, so the
      # base class's inherited generic `number` (a `Components::Code`) is nil.
      # Redefining `attribute :number, :string` on the shared,
      # **directly-instantiated** `Ieee::Identifier` base resolves against the
      # parent's `Components::Code` **nondeterministically under multi-flavor
      # load** (it passes IEEE-only but flips once every flavor is required,
      # e.g. the full suite). Applying the split only on leaf classes that are
      # never a superclass avoids that merge ambiguity — the same pattern
      # CIE/IHO/IETF use. Never define a `#number` *method*: it collides with
      # lutaml's generated accessor and corrupts attribute resolution.
      module CodeNumber
        def self.included(base)
          base.attribute :number, :string
          base.attribute :prefix, :string
          base.attribute :parts, :string, collection: true, default: -> { [] }
          base.attribute :separator, :string
        end

        # Accept keyword args or a single positional hash (the latter is what the
        # base #exclude/matching rebuild passes) — see Identifier#initialize.
        def initialize(args = {}, **kwargs)
          super
          sync_split_from_code_obj
        end

        # On the parse path `code_obj` is already built (base #initialize parses
        # it from the `code:` arg); hoist its fields onto the split attributes
        # so they serialize.
        def sync_split_from_code_obj
          co = code_obj
          return unless co

          self.number    = co.number
          self.prefix    = co.prefix
          self.parts     = co.parts
          self.separator = co.original_separator
        end

        # After from_hash there is no `code` string and no cached object, so
        # rebuild code_obj from the split fields. On the parse path base
        # #initialize already set @code_obj, so the `||=` returns it unchanged.
        def code_obj
          @code_obj ||= rebuild_code_obj_from_split
        end

        def rebuild_code_obj_from_split
          return nil if number.nil? || number.to_s.empty?

          nonempty_parts = parts.nil? || parts.empty? ? nil : parts
          Components::Code.new(
            prefix: prefix,
            number: number,
            parts: nonempty_parts,
            original_separator: separator,
          )
        end
      end
    end
  end
end
