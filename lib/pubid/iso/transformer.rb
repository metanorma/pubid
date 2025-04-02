require_relative "identifier/base"
require_relative "renderer/base"

module Pubid::Iso
  class Transformer < Pubid::Core::Transformer
    rule(root: subtree(:root)) do |context|
      if context[:root][:stage] == "stage-draft"
        case context[:root][:type]
        when "tr" then context[:root][:stage] = "DTR"
        when "ts" then context[:root][:stage] = "DTS"
        when "iwa" then context[:root][:stage] = "DIWA"
        when "pas" then context[:root][:stage] = "DPAS"
        when "guide" then context[:root][:stage] = "DGuide"
        else context[:root][:stage] = "D"
        end
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

    rule(supplements: subtree(:supplements)) do |context|
      if context[:supplements].is_a?(Array)
        context[:supplements] =
          context[:supplements].map do |supplement|
            if supplement[:typed_stage]
              supplement.merge(
                case supplement[:typed_stage]
                when "PDAM" then { typed_stage: "CD", type: "Amd" }
                when "pDCOR" then { typed_stage: "CD", type: "Cor" }
                # when "DAD" then { typed_stage: "WD", type: "Amd" }
                when "stage-draft"
                  if supplement[:type] == "sup"
                    { typed_stage: "DSuppl", type: "Suppl" }
                  else
                    { typed_stage: "WD" }
                  end
                else {}
                end
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

    rule(type: simple(:type)) do
      russian_type = Pubid::Iso::Renderer::Base::TRANSLATION[:russian][:type].key(type.to_s)
      { type: russian_type&.downcase&.to_sym ||
                        case type
                        # XXX: can't put 2 alternative Russian translations to dictionary, temporary hack
                        when "GUIDE", "Guide", "Руководство"
                          :guide
                        when "ТС", "TS"
                          :ts
                        when "ТО", "TR"
                          :tr
                        when "Directives Part", "Directives, Part", "Directives,", "DIR"
                          :dir
                        when "PAS"
                          :pas
                        when "DPAS"
                          :dpas
                        when "R"
                          :r
                        else
                          type
                        end }
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
        Identifier::Base.transform(**(context[:dir_joint_document].merge(type: :dir)))
      context.select { |k, v| k != :dir_joint_document }
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

    # Convert ISO stage to Russian and other formats if needed
    # @param code [String] ISO stage code
    # @return [Hash] a hash with keys :stage and optionally :type
    def self.convert_stage(code)
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
      # when "stage-draft" then { stage: "WD" }
      else { stage: code }
      end
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
  end
end
