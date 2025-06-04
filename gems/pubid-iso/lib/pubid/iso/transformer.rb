require_relative "identifier/base"
require_relative "renderer/base"

module Pubid::Iso
  class Transformer < Pubid::Core::Transformer
    rule(root: subtree(:root)) do |context|
      if context[:root][:stage] == "draft"
        context[:root][:stage] = convert_urn_stage context[:root][:type]
      end
      context[:root]
    end

    rule(edition: "Ed") do
      { edition: "1" }
    end

    rule(stage: subtree(:stage)) do |context|
      stage_and_type = convert_stage(context[:stage])
      context[:stage] = stage_and_type[:stage]
      context[:type] = stage_and_type[:type] if stage_and_type[:type]
      context
    end

    rule(supplements: subtree(:supplements)) do |context| # rubocop:disable Metrics/BlockLength
      if context[:supplements].is_a?(Array)
        context[:supplements] =
          context[:supplements].map do |supplement|
            if supplement[:typed_stage]
              supplement.merge(
                case supplement[:typed_stage]
                when "PDAM" then { typed_stage: "CD", type: "Amd" }
                when "pDCOR" then { typed_stage: "CD", type: "Cor" }
                # when "DAD" then { typed_stage: "WD", type: "Amd" }
                when "draft" then convert_urn_sup_draft_type supplement[:type]
                else convert_urn_sup_stage_code(supplement)
                end,
              )
            else
              case supplement[:type]
              when "Addendum" then supplement.merge({ type: "Add" })
              when "sup" then supplement.merge({ type: "Suppl" })
              else supplement
              end
            end
          end
      end
      context
    end

    rule(language: simple(:language)) do |context|
      if context[:language].to_s.include?("/")
        { language: context[:language]
          .to_s.split("/")
          .map { |code| convert_language(code) }.join(",") }
      else
        { language: convert_language(context[:language]) }
      end
    end

    rule(type: simple(:type)) do |context|
      russian_type = Pubid::Iso::Renderer::Base::TRANSLATION[:russian][:type].key(context[:type].to_s)
      { type: russian_type&.downcase&.to_sym || convert_type(context[:type]) }
    end

    rule(tctype: subtree(:tctype))  do |context|
      context[:type] = :tc
      context
    end

    rule(copublisher: sequence(:copublisher)) do |context|
      copublishers = context[:copublisher].map! do |publisher|
        convert_copublisher(publisher)
      end

      { copublisher: copublishers }
    end

    rule(copublisher: simple(:copublisher)) do |context|
      { copublisher: convert_copublisher(context[:copublisher]) }
    end

    rule(publisher: simple(:publisher)) do |context|
      { publisher: convert_publisher(context[:publisher]) }
    end

    rule(part: sequence(:part)) do
      { part: part.map(&:to_s).join("-") }
    end

    rule(joint_document: subtree(:joint_document)) do |context|
      context[:joint_document] =
        Identifier.create(**context[:joint_document])
      context
    end

    rule(dir_joint_document: subtree(:dir_joint_document)) do |context|
      context[:joint_document] =
        Identifier::Base.transform(**context[:dir_joint_document].merge(type: :dir))
      context.reject { |k, _| k == :dir_joint_document }
    end

    rule(jtc_dir: simple(:jtc_dir)) do |context|
      context[:type] = "DIR"
      context
    end

    def self.convert_publisher(publisher)
      pblsh = publisher.to_s.upcase
      Pubid::Iso::Renderer::Base::TRANSLATION[:russian][:publisher].key(pblsh) || pblsh
    end

    def self.convert_copublisher(copublisher)
      copblsh = convert_publisher copublisher
      Pubid::Iso::Renderer::Base::TRANSLATION[:french][:publisher].key(copblsh) || copblsh
    end

    rule(all_parts: simple(:all_parts)) do
      ["(all parts)", "ser"].include?(all_parts) ? { all_parts: true } : {}
    end

    # Convert ISO stage to Russian and other formats if needed
    # @param code [String] ISO stage code
    # @return [Hash] a hash with keys :stage and optionally :type
    def self.convert_stage(code) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength
      russian_code = Pubid::Iso::Renderer::Base::TRANSLATION[:russian][:stage].key(code.to_s)
      return { stage: russian_code } if russian_code

      case code
      when "NWIP" then { stage: "NP" }
      when "D", "FPD" then { stage: "DIS" }
      when "FD", "F" then { stage: "FDIS" }
      when "Fpr" then { stage: "PRF" }
      when "PDTR" then { stage: "CD", type: "TR" }
      when "PDTS" then { stage: "CD", type: "TS" }
      when "preCD" then { stage: "PreCD" }
      when "published" then { stage: "IS" }
      # when "draft" then { stage: "WD" }
      else { stage: convert_stage_code(code.to_s) }
      end
    end

    def self.convert_urn_sup_stage_code(sup)
      stage_type = convert_urn_sup_type(sup[:type])
      abbr = convert_stage_code(sup[:typed_stage])
      stage_type[:typed_stage] = abbr if abbr
      stage_type
    end

    def self.convert_urn_sup_type(type)
      case type
      when "sup" then { type: "Suppl" }
      when String, Parslet::Slice then { type: type.to_s }
      else {}
      end
    end

    def self.convert_stage_code(code)
      Identifier::InternationalStandard::TYPED_STAGES.each_value do |v|
        return v[:abbr] if v[:harmonized_stages].include?(code)
      end

      code
    end

    def self.convert_language(code)
      case code
      when "R" then "ru"
      when "F" then "fr"
      when "E" then "en"
      when "A" then "ar"
      else code
      end
    end

    def self.convert_urn_sup_draft_type(type)
      if type == "sup"
        { typed_stage: "DSuppl", type: "Suppl" }
      else
        { typed_stage: "WD" }
      end
    end

    def self.convert_urn_stage(type)
      case type
      when "tr" then "DTR"
      when "ts" then "DTS"
      when "iwa" then "DIWA"
      when "pas" then "DPAS"
      when "guide" then "DGuide"
      else "D"
      end
    end

    def self.convert_type(type) # rubocop:disable Metrics/CyclomaticComplexity,Metrics/MethodLength
      case type
      # XXX: can't put 2 alternative Russian translations to dictionary, temporary hack
      when "GUIDE", "Guide", "Руководство" then :guide
      when "ТС", "TS" then :ts
      when "ТО", "TR" then :tr
      when "Directives Part", "Directives, Part", "Directives,", "DIR" then :dir
      when "PAS" then :pas
      when "DPAS" then :dpas
      when "R" then :r
      else type
      end
    end
  end
end
