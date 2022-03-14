module Pubid::Ieee
  class Identifier
    attr_accessor :number, :publisher, :stage, :part, :status, :approval, :edition,
                :draft, :rev, :corr, :amd, :redline, :year, :month

    def initialize(**opts)
      opts.each { |key, value| send("#{key}=", value.is_a?(Array) && value || value.to_s) }
    end

    def self.parse(code)
      new(**Parser.new.parse(code).to_h)

    rescue Parslet::ParseFailed => failure
      raise Pubid::Iso::Errors::ParseError, "#{failure.message}\ncause: #{failure.parse_failure_cause.ascii_tree}"
    end

    def to_s
      "IEEE #{number}-#{year}"
    end
  end
end
