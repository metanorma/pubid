module Pubid::Ieee
  class Identifier
    attr_accessor :number, :publisher, :stage, :part, :subpart, :status, :approval,
                  :edition, :draft, :rev, :corr, :amd, :redline, :year, :month, :type

    def initialize(**opts)
      opts.each { |key, value| send("#{key}=", value.is_a?(Array) && value || value.to_s) }
    end

    def self.parse(code)
      new(**Parser.new.parse(code).to_h)

    rescue Parslet::ParseFailed => failure
      raise Pubid::Ieee::Errors::ParseError, "#{failure.message}\ncause: #{failure.parse_failure_cause.ascii_tree}"
    end

    def to_s
      "#{publisher} #{type}#{number}#{part}#{subpart}#{year}"
    end

    def part
      ".#{@part}" if @part
    end

    def subpart
      @subpart if @subpart && !@subpart.empty?
    end

    def type
      "#{@type} " if @type
    end

    def year
      "-#{@year}" if @year
    end
  end
end
