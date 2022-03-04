module PubidIso
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
                  :type, :year, :edition, :iteration, :supplements, :language

    def initialize(stage: nil, supplements: nil, **opts)
      if stage
        @stage = STAGES[stage.to_sym]
        @substage = 0
      end

      # XXX: temporary hack for ISO/IEC 19794-7:2014/Amd 1:2015/CD Cor 1 parsing
      supplements&.each do |supplement|
        if supplement[:stage]
          @stage = STAGES[Transformer.new.apply(stage: supplement[:stage].to_s)[:stage].to_sym]
          @substage = 0
        end
      end

      @supplements = supplements

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
      raise PubidIso::Errors::ParseError, "#{failure.message}\ncause: #{failure.parse_failure_cause.ascii_tree}"
    end
  end
end
