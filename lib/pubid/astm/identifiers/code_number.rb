# frozen_string_literal: true

module Pubid
  module Astm
    module Identifiers
      # Installs the flat, index-friendly code columns on every CONCRETE ASTM
      # identifier class.
      #
      # Why every concrete class and not Pubid::Astm::SingleIdentifier, which
      # they all inherit from: `number` redefines the parent
      # ::Pubid::Identifier's `attribute :number, Components::Code` as a plain
      # :string (Astm::Components::Code is not a subclass of it). Declaring that
      # on a class the concrete types INHERIT from resolves against the parent
      # definition nondeterministically under multi-flavor load — it passes an
      # ASTM-only run and can flip `root.number` to "" under the full suite (the
      # IEEE lesson; see lib/pubid/ieee/identifiers/code_number.rb and
      # CLAUDE.md).
      #
      # NOTE the module is included by `Standard` AND by `IsoDualPublished`,
      # which inherits from Standard. That is deliberate, not redundant: a class
      # that is itself inherited from must still declare the columns so its
      # subclass holds its own snapshot rather than relying on the parent's.
      # Every instantiable ASTM class declares them for itself.
      #
      # This matters because relaton-index sorts and bsearches every row on
      # `id.root.number.to_s`, and ASTM kept identity in an
      # Astm::Components::Code under a `code` attribute, so all 248 parseable
      # fixture ids keyed "".
      module CodeNumber
        def self.included(base)
          # Bare document number ("2938"), the relaton index key. `letter` is a
          # sibling column, so E2938 and D2938 narrow to the same bucket and
          # are then separated by the full hash — the IEEE prefix/number split.
          base.attribute :number, :string
          base.attribute :letter, :string
          base.attribute :suffix, :string
          base.attribute :subseries, :string
          # Named for the RARE case with a false default, so the canonical
          # to_hash drops it from every ordinary row.
          base.attribute :dual_m, :boolean, default: -> { false }
        end

        # The composed document code, rebuilt on demand from the split columns.
        # ASTM's renderer reads the individual fields (`code.letter`,
        # `code.number`, `code.dual_m`) in several places, so the component has
        # to keep its structure rather than collapsing to a string as ASME's
        # does.
        #
        # Deliberately NOT an attribute and NOT memoised: the columns are
        # writable (the base #exclude rebuilds through them), so a cached Code
        # would go stale. nil when there is no number and no letter, preserving
        # the nil-`code` branches the renderer and URN generator both test.
        def code
          return nil if number.nil? && letter.nil?

          Components::Code.new(
            letter: letter,
            number: number,
            suffix: suffix,
            subseries: subseries,
            dual_m: dual_m,
          )
        end

        # Every field of the code is identity-bearing — Code#to_s renders all
        # of them and they are all in the serialized hash — so all of them must
        # reach the slug, or two distinct documents share a filename.
        # CLAUDE.md's rule: a marker that only reaches `==` is not enough.
        def mr_number_with_part
          segments = [letter, number, suffix].compact
          segments << "s#{subseries}" if subseries
          segments << "m" if dual_m
          return nil if segments.empty?

          segments.join("-").downcase.gsub(/[^a-z0-9-]+/, "-")
            .gsub(/\A-+|-+\z/, "")
        end
      end
    end
  end
end
