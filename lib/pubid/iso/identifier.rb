module Pubid::Iso
  class Identifier
    STAGES = { NP: 10,
               WD: 20,
               CD: 30,
               DIS: 40,
               FDIS: 50,
               PRF: 50,
               IS: 60,
               Fpr: 50 }.freeze

    attr_accessor :number, :publisher, :copublisher, :stage, :substage, :part,
                  :type, :year, :edition, :iteration, :supplements, :language,
                  :amendment, :amendment_version, :amendment_number,
                  :corrigendum, :corrigendum_version, :corrigendum_number

    def initialize(stage: nil, supplements: nil, **opts)
      if stage
        @stage = STAGES[stage.to_sym]
        @substage = 0
      end

      opts.each { |key, value| send("#{key}=", value.is_a?(Array) && value || value.to_s) }
    end

    def urn
      URN.new(self)
    end

    def self.parse(code)
      new(**Parser.new.parse(code).map do |k, v|
        Transformer.new.apply(k => v).to_a.first
      end.to_h)
    rescue Parslet::ParseFailed => failure
      raise Pubid::Iso::Errors::ParseError, "#{failure.message}\ncause: #{failure.parse_failure_cause.ascii_tree}"
    end
  end
end
