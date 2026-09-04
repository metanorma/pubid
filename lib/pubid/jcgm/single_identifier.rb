# frozen_string_literal: true

module Pubid
  module Jcgm
    class SingleIdentifier < Identifier
      attribute :publisher, Jcgm::Components::Publisher,
                default: -> { self.class.default_publisher }
      attribute :typed_stage, Pubid::Components::TypedStage,
                default: -> { self.class.published_typed_stage }
      attribute :date, Pubid::Components::Date
      attribute :languages, Pubid::Components::Language, collection: true
      attribute :stage, Pubid::Components::Stage
      attribute :type, Pubid::Components::Type

      # Compact serialization: only per-instance information is mapped. The
      # publisher (always "JCGM") and the derived type / stage / typed_stage
      # (fully determined by the class, i.e. `_type`) are intentionally NOT
      # mapped — they are reconstructed from the class on load via the
      # attribute defaults above. Components collapse to bare scalars:
      # number is already a bare :string; date -> year/month/day scalars.
      # Mirrors ISO (lib/pubid/iso/identifier.rb) and OIML.
      key_value do
        map "_type", to: :_type
        map "number", with: { to: :number_to_kv, from: :number_from_kv }
        map "year", with: { to: :year_to_kv, from: :year_from_kv }
        map "month", with: { to: :month_to_kv, from: :month_from_kv }
        map "day", with: { to: :day_to_kv, from: :day_from_kv }
        map "languages", to: :languages
      end

      # The publisher implied when none is serialized — always JCGM.
      def self.default_publisher
        Jcgm::Components::Publisher.new(publisher: Jcgm::PREFIXES.first)
      end

      # The class's published typed_stage (canonical surface form). Each JCGM
      # class registers exactly one, all :published; `_type` fixes the class,
      # so an omitted typed_stage reconstructs deterministically on from_hash.
      #
      # `original_abbr` is deliberately LEFT NIL. It records the spelling the
      # input used and is not serialized, so it cannot survive a round trip —
      # and this method is one of the two paths that fill `typed_stage`. The
      # other is the parse path (`Builder#locate_typed_stage` ->
      # `Jcgm.locate_stage`), which returns the registry entry untouched.
      # Setting it here made the two disagree, so `from_hash(to_hash) != parse`
      # for every type the grammar tags (Meeting, Corrigendum, Amendment) —
      # and because `#matches?` is `exclude(...) == other.exclude(...)`, a
      # relaton index lookup then silently matched nothing. Nothing in JCGM
      # reads the field: the renderer hardcodes its surface words, the URN
      # generator reads only `type_code`, and `TypedStage#abbreviation` chooses
      # among long_abbr/short_abbr/abbr.first. Recording the *matched* token
      # instead would not work either — "/Cor 1" would store "Cor" where
      # from_hash rebuilds "Corrigendum".
      def self.published_typed_stage
        return nil unless const_defined?(:TYPED_STAGES)

        ts = self::TYPED_STAGES.find { |t| t.stage_code.to_s == "published" }
        # dup: locate_stage hands out the shared object from the frozen
        # TYPED_STAGES array (the array is frozen, its elements are not), so a
        # future in-place mutation would otherwise leak globally.
        ts&.dup
      end

      # type and stage are derived from typed_stage, never stored — so the
      # doctype (fixed by the class / _type) is not carried in the hash.
      def type
        typed_stage&.to_type
      end

      def stage
        typed_stage&.to_stage
      end

      # --- number ---
      def number_to_kv(model, doc) = emit_kv(doc, "number", model.number)
      def number_from_kv(model, value) = model.number = value.to_s

      # --- date flattened to top-level year/month/day scalars ---
      def year_to_kv(model, doc) = emit_kv(doc, "year", model.date&.year)
      def month_to_kv(model, doc) = emit_kv(doc, "month", model.date&.month)
      def day_to_kv(model, doc) = emit_kv(doc, "day", model.date&.day)
      def year_from_kv(model, value) = date_for(model).year = value.to_s
      def month_from_kv(model, value) = date_for(model).month = value.to_s
      def day_from_kv(model, value) = date_for(model).day = value.to_s

      def emit_kv(doc, key, value)
        return if value.nil? || value.to_s.empty?

        doc.add_child(Lutaml::KeyValue::DataModel::Element.new(key, value.to_s))
      end

      def date_for(model)
        model.date ||= Pubid::Components::Date.new
      end

      def publisher_portion
        publisher.to_s
      end

      def number_portion
        parts = []
        parts << number if number
        parts << ":#{date.year}" if date
        parts.join
      end

      def language_portion
        return "" unless languages&.any?

        [
          "(",
          languages.map(&:original_code).join("/"),
          ")",
        ].join
      end
    end
  end
end
