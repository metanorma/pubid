module PubidIso
  class Identifier
    attr_accessor :number, :copublisher, :stage, :part

    def initialize(**opts)
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
