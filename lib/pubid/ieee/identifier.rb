require 'date'
require "yaml"

UPDATE_CODES = YAML.load_file(File.join(File.dirname(__FILE__), "../../../update_codes.yaml"))

module Pubid::Ieee
  class Identifier
    attr_accessor :number, :publisher, :copublisher, :stage, :part, :subpart,
                  :edition, :draft, :redline, :year, :month, :type, :alternative,
                  :draft_status, :revision, :adoption_year, :amendment, :supersedes,
                  :corrigendum, :corrigendum_comment, :reaffirmed

    def initialize(type_status:, number:, parameters:,
                   organizations: { publisher: "IEEE" }, revision: nil)
      @number = number
      @revision = revision
      [organizations, type_status, parameters].each do |data|
        case data
        when Hash
          set_values(data.transform_values do |v|
            (v.is_a?(Array) && v.first.is_a?(Hash) && merge_parameters(v)) || v
          end)
        when Array
          set_values(merge_parameters(data))
        end
      end
    end

    def set_values(hash)
      hash.each { |key, value| send("#{key}=", value.is_a?(Parslet::Slice) && value.to_s || value) }
    end

    def self.update_old_code(code)
      UPDATE_CODES.each do |from, to|
        code = code.gsub(from.match?(/^\/.*\/$/) ? Regexp.new(from[1..-2]) : from, to)
      end
      code
    end

    def merge_parameters(params)
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
      new(**Transformer.new.apply(Parser.new.parse(update_old_code(code))).to_h)

    rescue Parslet::ParseFailed => failure
      raise Pubid::Ieee::Errors::ParseError, "#{failure.message}\ncause: #{failure.parse_failure_cause.ascii_tree}"
    end

    def to_s(format = :short)
      "#{identifier(format)}#{revision}#{amendment}#{redline}#{adoption}"
    end

    def identifier(format = :short)
      "#{publisher}#{copublisher} #{draft_status(format)}#{type(format)}#{number}#{part}"\
        "#{subpart}#{year}#{corrigendum}#{draft}#{edition}#{alternative}#{supersedes}#{reaffirmed}"
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
      "#{@part}" if @part
    end

    def subpart
      @subpart if @subpart && !@subpart.empty?
    end

    def type(format)
      result = @draft && format == :full ? "Draft " : ""
      result += "#{@type} " if @type
      result
    end

    def year
      return "" unless @year

      if @corrigendum_comment
        @corrigendum_comment.year
      elsif @reaffirmed && @reaffirmed.key?(:reaffirmation_of)
        @reaffirmed[:reaffirmation_of].year
      else
        "-#{@year}"
      end
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

    def draft
      return "" unless @draft

      result = "/D#{@draft[:version].is_a?(Array) ? @draft[:version].join('D') : @draft[:version]}"
      result += ".#{@draft[:revision]}" if @draft[:revision]
      result += ", #{@draft[:month]}" if @draft[:month]
      result += " #{@draft[:day]}," if @draft[:day]
      result += " #{@draft[:year]}" if @draft[:year]
      result
    end

    def draft_status(format)
      "#{@draft_status} " if @draft_status && format == :full
    end

    def revision
      " (Revision of #{@revision.join(' and ')})" if @revision
    end

    def amendment
      return unless @amendment

      return " (Amendment to #{@amendment})" unless @amendment.is_a?(Array)

      result = " (Amendment to #{@amendment.first} as amended by "
      result += if @amendment.length > 2
                  "#{@amendment[1..-2].map(&:to_s).join(', ')}, and #{@amendment[-1]}"
                else
                  @amendment.last.to_s
                end

      "#{result})"
    end

    def redline
      " - Redline" if @redline
    end

    def adoption
      if @adoption_year
        adoption_id = dup
        adoption_id.year = @adoption_year
        " (Adoption of #{adoption_id.identifier})"
      end
    end

    def supersedes
      return unless @supersedes

      if @supersedes.length > 2
        " (Supersedes #{@supersedes.join(', ')})"
      else
        " (Supersedes #{@supersedes.join(' and ')})"
      end
    end

    def corrigendum
      if @corrigendum.nil?
        (@year && @corrigendum_comment && "/Cor 1-#{@year}") || ""
      else
        if @corrigendum[:year]
          "/Cor #{@corrigendum[:version]}-#{@corrigendum[:year]}"
        else
          "/Cor #{@corrigendum[:version]}"
        end
      end
    end

    def reaffirmed
      return unless @reaffirmed

      return " (Reaffirmed #{@year})" if @reaffirmed.key?(:reaffirmation_of)

      " (Reaffirmed #{@reaffirmed[:year]})" if @reaffirmed[:year]
    end
  end
end
