# frozen_string_literal: true

module Pubid
  module Iec
    # Mixin for pure wrapper identifiers (Vap/Consolidated/Sheet) whose common
    # ID fields are delegated to a wrapped base. lutaml merges a subclass's
    # key_value block onto the parent's, so without this the delegated fields
    # would serialize twice — once at the wrapper's top level and once inside
    # "base". No-op the delegated maps so they serialize once. (Mirrors
    # Iso::BundledIdentifier.) Fragment keeps its own stage/edition, so it
    # suppresses a subset inline instead of including this.
    module DelegatedFieldSuppression
      def number_to_kv(_model, _doc); end
      def part_to_kv(_model, _doc); end
      def subpart_to_kv(_model, _doc); end
      def stage_iteration_to_kv(_model, _doc); end
      def year_to_kv(_model, _doc); end
      def publisher_to_kv(_model, _doc); end
      def copublishers_to_kv(_model, _doc); end
      def stage_to_kv(_model, _doc); end
    end

    class Identifier < ::Pubid::Identifier
      # Override base types with IEC-specific ones. publisher defaults to the
      # type's implied publisher (IEC), so an omitted publisher key reconstructs
      # correctly on from_hash. number/part/subpart are IEC codes.
      attribute :publisher, ::Pubid::Iec::Components::Publisher,
                default: -> { self.class.default_publisher }
      attribute :copublishers, ::Pubid::Iec::Components::Publisher,
                collection: true
      attribute :number, ::Pubid::Iec::Components::Code
      attribute :part, ::Pubid::Iec::Components::Code
      attribute :subpart, ::Pubid::Iec::Components::Code

      # The publisher implied when none is serialized (IEC for every type).
      def self.default_publisher
        ::Pubid::Iec::Components::Publisher.new(body: "IEC")
      end

      # typed_stage is the single source of truth for stage (and, with the
      # class, the doctype). Default to the class's published typed_stage so an
      # omitted "stage" key reconstructs the published state on from_hash.
      attribute :typed_stage, ::Pubid::Components::TypedStage,
                default: -> { self.class.published_typed_stage }

      # The class's published typed_stage (canonical surface form), or nil for
      # types without a published stage.
      #
      # `original_abbr` is deliberately LEFT NIL. It records the spelling the
      # input used, it is not serialized, and the parse path (Builder#
      # locate_typed_stage) never writes it — so setting it here alone made
      # `from_hash(to_hash) != parse` for every IEC identifier. The `dup` stays:
      # TYPED_STAGES is frozen, its elements are not.
      def self.published_typed_stage
        return nil unless const_defined?(:TYPED_STAGES)

        ts = self::TYPED_STAGES.find { |t| t.stage_code.to_s == "published" }
        ts&.dup
      end

      # type and generic stage are derived from typed_stage, never stored — so
      # the doctype (fixed by the class / _type) can't be lost when "stage" is
      # omitted for the published default.
      def type
        typed_stage&.to_type
      end

      def stage
        typed_stage&.to_stage
      end

      # Polymorphic type map for lutaml::Model key_value serialization. Maps
      # polymorphic_name -> class name for from_hash dispatch. Includes the
      # compound wrappers (Consolidated/Vap/Sheet) and the synthetic
      # SingleIdentifier base, which appear as nested `_type` values even though
      # they aren't identifier_types. Validated against build_type_map by spec.
      IEC_TYPE_MAP = {
        "pubid:iec:international-standard" => "Pubid::Iec::Identifiers::InternationalStandard",
        "pubid:iec:technical-specification" => "Pubid::Iec::Identifiers::TechnicalSpecification",
        "pubid:iec:technical-report" => "Pubid::Iec::Identifiers::TechnicalReport",
        "pubid:iec:publicly-available-specification" => "Pubid::Iec::Identifiers::PubliclyAvailableSpecification",
        "pubid:iec:guide" => "Pubid::Iec::Identifiers::Guide",
        "pubid:iec:operational-document" => "Pubid::Iec::Identifiers::OperationalDocument",
        "pubid:iec:component-specification" => "Pubid::Iec::Identifiers::ComponentSpecification",
        "pubid:iec:conformity-assessment" => "Pubid::Iec::Identifiers::ConformityAssessment",
        "pubid:iec:societal-technology-trend-report" => "Pubid::Iec::Identifiers::SocietalTechnologyTrendReport",
        "pubid:iec:systems-reference-document" => "Pubid::Iec::Identifiers::SystemsReferenceDocument",
        "pubid:iec:technology-report" => "Pubid::Iec::Identifiers::TechnologyReport",
        "pubid:iec:technical-group" => "Pubid::Iec::Identifiers::TechnicalGroup",
        "pubid:iec:test-report-form" => "Pubid::Iec::Identifiers::TestReportForm",
        "pubid:iec:white-paper" => "Pubid::Iec::Identifiers::WhitePaper",
        "pubid:iec:working-document" => "Pubid::Iec::Identifiers::WorkingDocument",
        "pubid:iec:amendment" => "Pubid::Iec::Identifiers::Amendment",
        "pubid:iec:corrigendum" => "Pubid::Iec::Identifiers::Corrigendum",
        "pubid:iec:interpretation-sheet" => "Pubid::Iec::Identifiers::InterpretationSheet",
        "pubid:iec:fragment-identifier" => "Pubid::Iec::Identifiers::FragmentIdentifier",
        "pubid:iec:consolidated-identifier" => "Pubid::Iec::Identifiers::ConsolidatedIdentifier",
        "pubid:iec:vap-identifier" => "Pubid::Iec::Identifiers::VapIdentifier",
        "pubid:iec:sheet-identifier" => "Pubid::Iec::Identifiers::SheetIdentifier",
        "pubid:iec:base" => "Pubid::Iec::Identifiers::Base",
        "pubid:iec:single-identifier" => "Pubid::Iec::SingleIdentifier",
      }.freeze

      # SingleIdentifier lives outside Pubid::Iec::Identifiers but appears as a
      # nested `_type`, so the shared polymorphic_type_map needs it explicitly
      # (see Pubid::Identifier#additional_identifier_classes).
      def self.additional_identifier_classes
        [Pubid::Iec::SingleIdentifier]
      end
      private_class_method :additional_identifier_classes

      # Build the type map from the live class list, for the validation spec.
      def self.build_type_map
        types = Pubid::Iec.identifier_types
        extra = [Identifiers::ConsolidatedIdentifier, Identifiers::VapIdentifier,
                 Identifiers::SheetIdentifier, Identifiers::Base, SingleIdentifier]
        (types + extra).uniq.to_h { |klass| [klass.polymorphic_name, klass.name] }
      end

      # The base Pubid::Identifier no longer auto-maps attributes, so each
      # flavor's top class declares its own key_value mapping. Subclasses merge
      # their own blocks on top of this one (e.g. SupplementIdentifier adds
      # base; VapIdentifier adds vap), so list every base attribute IEC
      # serializes here once. Code/Date are flattened to plain scalars; the
      # verbose type/stage trees are not mapped (type/stage are recomputed from
      # typed_stage, which serializes as just its code under "stage").
      key_value do
        map "_type", to: :_type, polymorphic_map: IEC_TYPE_MAP
        # Code components serialize as their plain string value, not {value,...}.
        map "number", with: { to: :number_to_kv, from: :number_from_kv }
        map "part", with: { to: :part_to_kv, from: :part_from_kv }
        map "subpart", with: { to: :subpart_to_kv, from: :subpart_from_kv }
        map "stage_iteration",
            with: { to: :stage_iteration_to_kv, from: :stage_iteration_from_kv }
        # date serialized flat as year/month/day, nils omitted.
        map "year", with: { to: :year_to_kv, from: :year_from_kv }
        map "month", with: { to: :month_to_kv, from: :month_from_kv }
        map "day", with: { to: :day_to_kv, from: :day_from_kv }
        # IEC undated reference (e.g. IEC 60050:--). The `false` default is
        # omitted; only the meaningful `true` round-trips via to_hash.
        map "undated", with: { to: :undated_to_kv, from: :undated_from_kv }
        map "edition", to: :edition, render_default: false
        map "languages", to: :languages, render_default: false
        # publisher emitted only when the primary isn't the IEC default;
        # copublishers (the other bodies) as an array, omitted when empty.
        map "publisher", with: { to: :publisher_to_kv, from: :publisher_from_kv }
        map "copublishers",
            with: { to: :copublishers_to_kv, from: :copublishers_from_kv }
        # `type` and generic `stage` are fully derived from `typed_stage`, so we
        # serialize only the unique typed-stage code under "stage" and recompute
        # the rest on load. _type already pins the document type.
        map "stage", with: { to: :stage_to_kv, from: :stage_from_kv }
        # Omit the `false` default; only the meaningful `true` is serialized.
        map "all_parts", with: { to: :all_parts_to_kv, from: :all_parts_from_kv }
      end

      # --- Code components <-> plain string ---
      def number_to_kv(model, doc) = emit_code(doc, "number", model.number)
      def number_from_kv(model, value) = model.number = build_code(value)
      def part_to_kv(model, doc) = emit_code(doc, "part", model.part)
      def part_from_kv(model, value) = model.part = build_code(value)
      def subpart_to_kv(model, doc) = emit_code(doc, "subpart", model.subpart)
      def subpart_from_kv(model, value) = model.subpart = build_code(value)

      def emit_code(doc, key, code)
        v = code.is_a?(::Pubid::Components::Code) ? code.value : code
        return if v.nil? || v.to_s.empty?

        doc.add_child(Lutaml::KeyValue::DataModel::Element.new(key, v.to_s))
      end

      def build_code(value)
        return if value.nil? || value.to_s.empty?

        ::Pubid::Iec::Components::Code.new(value: value.to_s)
      end

      def stage_iteration_to_kv(model, doc)
        iter = model.stage_iteration
        v = iter.is_a?(::Pubid::Components::Iteration) ? iter.number : iter
        return if v.nil? || v.to_s.empty?

        doc.add_child(Lutaml::KeyValue::DataModel::Element.new("stage_iteration",
                                                              v.to_s))
      end

      def stage_iteration_from_kv(model, value)
        return if value.nil? || value.to_s.empty?

        model.stage_iteration =
          ::Pubid::Components::Iteration.new(number: value.to_s)
      end

      # --- date serialized flat as year/month/day ---
      def year_to_kv(model, doc)
        y = model.date&.year
        return if y.nil? || y.to_s.empty?

        doc.add_child(Lutaml::KeyValue::DataModel::Element.new("year", y.to_s))
      end

      def year_from_kv(model, value)
        return if value.nil? || value.to_s.empty?

        (model.date ||= ::Pubid::Components::Date.new).year = value.to_s
      end

      def month_to_kv(model, doc)
        m = model.date&.month
        return if m.nil? || m.to_s.empty?

        doc.add_child(Lutaml::KeyValue::DataModel::Element.new("month", m.to_s))
      end

      def month_from_kv(model, value)
        return if value.nil? || value.to_s.empty?

        (model.date ||= ::Pubid::Components::Date.new).month = value.to_s
      end

      def day_to_kv(model, doc)
        d = model.date&.day
        return if d.nil? || d.to_s.empty?

        doc.add_child(Lutaml::KeyValue::DataModel::Element.new("day", d.to_s))
      end

      def day_from_kv(model, value)
        return if value.nil? || value.to_s.empty?

        (model.date ||= ::Pubid::Components::Date.new).day = value.to_s
      end

      # --- date undated flag (IEC undated reference, e.g. IEC 60050:--) ---
      # The `false` default is omitted; only the meaningful `true` round-trips
      # via to_hash / from_hash.
      def undated_to_kv(model, doc)
        return unless model.date&.undated?

        doc.add_child(Lutaml::KeyValue::DataModel::Element.new("undated", true))
      end

      def undated_from_kv(model, value)
        (model.date ||= ::Pubid::Components::Date.new).undated = value.to_s == "true"
      end

      # --- publisher: primary only when non-default; copublishers as a list ---
      def publisher_to_kv(model, doc)
        pub = model.publisher&.body
        return if pub.nil? || pub == model.class.default_publisher&.body

        doc.add_child(Lutaml::KeyValue::DataModel::Element.new("publisher", pub))
      end

      def publisher_from_kv(model, value)
        return if value.nil? || value.to_s.empty?

        model.publisher = ::Pubid::Iec::Components::Publisher.new(body: value.to_s)
      end

      def copublishers_to_kv(model, doc)
        cp = model.copublishers
        return unless cp&.any?

        doc.add_child(
          Lutaml::KeyValue::DataModel::Element.new("copublishers", cp.map(&:body)),
        )
      end

      def copublishers_from_kv(model, value)
        list = Array(value).map(&:to_s)
        return unless list.any?

        model.copublishers = list.map do |cp|
          ::Pubid::Iec::Components::Publisher.new(body: cp)
        end
      end

      # --- all_parts: omit the false default ---
      def all_parts_to_kv(model, doc)
        return unless model.all_parts

        doc.add_child(Lutaml::KeyValue::DataModel::Element.new("all_parts", true))
      end

      def all_parts_from_kv(model, value)
        model.all_parts = value
      end

      # Serialize typed_stage as just its unique code (e.g. "cd", "fdis"); the
      # published default is omitted (recomputed from the class on load).
      def stage_to_kv(model, doc)
        ts = model.typed_stage
        return unless ts&.code
        return if ts.stage_code.to_s == "published"

        doc.add_child(
          Lutaml::KeyValue::DataModel::Element.new("stage", ts.code.to_s),
        )
      end

      # Resolve the typed-stage code back within this identifier's class.
      # `original_abbr` is left nil here for the same reason as in
      # `published_typed_stage` above.
      def stage_from_kv(model, value)
        return if value.nil? || value.to_s.empty?

        ts = (model.class.const_defined?(:TYPED_STAGES) &&
              model.class::TYPED_STAGES.find { |t| t.code.to_s == value.to_s }) ||
             Pubid::Iec.all_typed_stages.find { |t| t.code.to_s == value.to_s }
        return unless ts

        model.typed_stage = ts.dup
      end

      def self.parse(string)
        if string.length > Pubid::MAX_INPUT_LENGTH
          raise ArgumentError, Pubid::INPUT_TOO_LONG_MESSAGE
        end

        # Route URN strings to the URN parser (mirrors Iso::Identifier.parse)
        if Pubid::FormatDetector.detect(string) == :urn
          return Pubid::Iec::UrnParser.parse(string)
        end

        # Apply legacy update_codes normalization first, before any other preprocessing
        normalized = Core::UpdateCodes.apply(string, :iec)
        parsed = Pubid::Iec::Parser.new.parse(normalized)
        if parsed.nil? || parsed.empty?
          raise Pubid::Iec::Parser::ParseError,
                "Invalid identifier format"
        end

        Pubid::Iec::Builder.new.build(parsed)
      end

      # from_hash is the shared polymorphic dispatch on Pubid::Identifier.
      # IEC_TYPE_MAP remains as the key_value polymorphic_map.
    end
  end
end
