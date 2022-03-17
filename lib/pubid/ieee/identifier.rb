require 'date'

module Pubid::Ieee
  class Identifier
    attr_accessor :number, :publisher, :copublisher, :stage, :part, :subpart, :status, :approval,
                  :edition, :draft, :rev, :corr, :amd, :redline, :year, :month, :type, :alternative

    def initialize(**opts)
      opts.each { |key, value| send("#{key}=", value.is_a?(Enumerable) && value || value.to_s) }
    end

    def self.merge_parameters(params)
      return params unless params.is_a?(Array)

      result = {}
      params.each do |item|
        item.each do |key, value|
          if result.key?(key)
            result[key] = result[key].is_a?(Array) ? result[key] << value : [result[key], value]
          else
            result[key] = value
          end
        end
      end
      result
    end

    def self.parse(code)
      new(**merge_parameters(Parser.new.parse(code)).to_h)

    rescue Parslet::ParseFailed => failure
      raise Pubid::Ieee::Errors::ParseError, "#{failure.message}\ncause: #{failure.parse_failure_cause.ascii_tree}"
    end

    def to_s
      "#{publisher}#{copublisher} #{type}#{number}#{part}#{subpart}#{year}#{edition}#{alternative}"
    end

    def copublisher
      return "" unless @copublisher

      if @copublisher.is_a?(Array)
        @copublisher&.map { |c| "/#{c}" }&.join
      else
        "/#{@copublisher}"
      end
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

    def alternative
      if @alternative
        if @alternative.is_a?(Array)
          " (#{@alternative.map { |a| Identifier.new(**a) }.join(', ')})"
        else
          " (#{Identifier.new(**@alternative)})"
        end
      end
    end

    def edition
      return "" unless @edition

      result = " Edition "
      if @edition[:version]
        result += @edition[:version] == "First" ? "1.0 " : "#{@edition[:version]} "
      end

      result += "#{@edition[:year]}" if @edition[:year]
      if @edition[:month]
        month = @edition[:month]
        month = Date.parse(@edition[:month]).month if month.to_i.zero?
        result += "-#{sprintf('%02d', month)}"
      end
      result += "-#{@edition[:day]}" if @edition[:day]
      result
    end
  end
end
