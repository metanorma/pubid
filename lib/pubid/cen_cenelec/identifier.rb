# frozen_string_literal: true

module Pubid
  module CenCenelec
    # Common base class for all CEN/CENELEC identifiers. CEN/CENELEC has a split
    # hierarchy — some concrete types descend from Identifiers::Base, others from
    # SingleIdentifier — so this class is the shared parent of BOTH, making every
    # CEN/CENELEC identifier `is_a?(Pubid::CenCenelec::Identifier)` natively (and
    # giving them the shared polymorphic `from_hash`). No facade needed.
    class Identifier < ::Pubid::Identifier
      # `number`/`part`/`subpart` are declared here rather than inherited as a
      # Components::Code: CEN/CENELEC stores a bare string in every one of them.
      # This class is the shared parent of BOTH branches, so one declaration
      # here replaces the three that used to disagree (Identifiers::Base said
      # :string, SingleIdentifier inherited Code, SupplementIdentifier declared
      # Code again). Declaring here is safe because this body lives in one file
      # and is never reopened, so every subclass body opens after it has run
      # (lutaml deep-dups the parent attribute table at class-definition time).
      attribute :number, :string
      attribute :part, :string
      attribute :subpart, :string
      # The ETSI-style version suffix ("EN 302 326-2 V2.2.1")
      attribute :version, :string

      # A published European Norm holds no type, stage or typed stage, so a
      # nil one means "published", not "any stage": `EN 1325` is not
      # `prEN 1325`, and `EN 1991` is not `ENV 1991`. The three components
      # repeat one entry of the stage registry, so they move together.
      subset_strict :type, :stage, :typed_stage

      # The publisher serializes as a bare string ("publisher" => "CEN"), and
      # the copublishers as a list of strings. The shared table does not do
      # this for every flavor, because IEEE has a published index whose rows
      # hold the nested {"body" => …} form.
      def self.flat_scalar_components
        super.merge(publisher: "publisher", copublishers: "copublishers")
      end

      def self.flat_scalar_fields
        super.merge(publisher: :body, copublishers: :body)
      end

      # A draft stage serializes as its typed-stage code ("stage" => "pren"),
      # as ISO ("dis") and IEC ("cd") do. The `type`, `stage` and
      # `typed_stage` components all repeat one entry of the stage registry,
      # so the code is enough, and #inflate_scalar_components rebuilds the
      # three from it. The short form is written only when the three are
      # exactly what the registry entry gives; any other combination keeps
      # the nested components, so the round trip stays exact.
      def self.compact_hash(model, hash)
        stage = model.typed_stage
        return unless stage && hash.key?("typed_stage")
        return unless model.type == stage.to_type &&
          model.stage == stage.to_stage

        hash.delete("type")
        hash.delete("typed_stage")
        hash["stage"] = stage.code.to_s
      end

      # Reads the short stage form back; see #compact_hash. The nested form
      # still reads as before.
      def self.inflate_scalar_components(data)
        data = super
        return data unless data.is_a?(::Hash) && component_attribute?(:stage)

        key = data.key?("stage") ? "stage" : :stage
        value = data[key]
        return data unless value.is_a?(::String) || value.is_a?(::Symbol)

        stage = CenCenelec.locate_stage_by_code(value)
        return data unless stage

        data = data.dup
        data.delete(key)
        data["type"] = stage.to_type.to_hash
        data["stage"] = stage.to_stage.to_hash
        data["typed_stage"] = stage.to_hash
        data
      end

      # The slug names a draft stage by its code ("en.pren.1234.2020"), so a
      # prEN, an FprEN and an EN with one number and year get three slugs.
      # The shared hook gave the type code "en" for all of them.
      def mr_type
        stage = typed_stage
        return super unless stage && stage.stage_code.to_s != "published"

        stage.code.to_s.downcase
      end

      # The CEN year rule (`:year` vs `:supplement_year`) is the shared
      # `::Pubid::Identifier#exclude` mechanism driven by `Amendment`'s and
      # `Corrigendum`'s `supplement_date_attributes` — no override needed
      # here. Detail: `lib/pubid/cen_cenelec/CLAUDE.md`'s year-rule bullet.

      def self.parse(identifier)
        unless identifier.is_a?(String)
          raise Pubid::Errors::InvalidInputError,
                Pubid::INPUT_NOT_A_STRING_MESSAGE
        end

        if identifier.length > Pubid::MAX_INPUT_LENGTH
          raise Pubid::Errors::InvalidInputError, Pubid::INPUT_TOO_LONG_MESSAGE
        end

        normalized = Parser.normalize_input(identifier)
        parsed = Pubid::Parg::Backend.parse(:cen_cenelec, normalized)
        Builder.new.build(parsed)
      end

      private

      # "amd.1.2005" from ("amd", "1", 2005). A nil or blank segment is left
      # out, so an unnumbered "/AC:2003" gives "cor.2003", not "cor..2003".
      def mr_join_segments(*segments)
        segments.map(&:to_s).reject(&:empty?).join(".").downcase
      end
    end
  end
end
