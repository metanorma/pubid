module PubidIso
  class Identifier
    STAGES = { NP: 10,
               WD: 20,
               CD: 30,
               DIS: 40,
               FDIS: 50,
               PRF: 50,
               IS: 60 }.freeze

    attr_accessor :number, :copublisher, :stage, :substage, :part

    def initialize(stage: nil, **opts)
      if stage
        @stage = STAGES[stage.to_sym]
        @substage = 0
      end
      opts.each { |key, value| send("#{key}=", value.to_s) }
    end

    def urn
      URN.new(self)
    end

    def self.parse(code)
      new(**Parser.new.parse(code))
    rescue Parslet::ParseFailed => failure
      raise PubidIso::Errors::ParseError, "#{failure.message}\ncause: #{failure.parse_failure_cause.ascii_tree}"
    end
  end
end
