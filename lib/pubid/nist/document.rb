# frozen_string_literal: true

require "json"

UPDATE_CODES = YAML.load_file(File.join(File.dirname(__FILE__), "../../../update_codes.yaml"))

REVISION_DESC = {
  long: ", Revision ",
  abbrev: ", Rev. ",
  short: "r",
  mr: "r",
}.freeze

VERSION_DESC = {
  long: ", Version ",
  abbrev: ", Ver. ",
  short: "ver",
  mr: "ver",
}.freeze

VOLUME_DESC = {
  long: ", Volume ",
  abbrev: ", Vol. ",
  short: "v",
  mr: "v",
}.freeze

PART_DESC = {
  long: " Part ",
  abbrev: " Pt. ",
  short: "pt",
  mr: "pt",
}.freeze

EDITION_DESC = {
  long: " Edition ",
  abbrev: " Ed. ",
  short: "e",
  mr: "e",
}.freeze

SUPPLEMENT_DESC = {
  long: " Supplement ",
  abbrev: " Suppl. ",
  short: "sup",
  mr: "sup",
}.freeze

SECTION_DESC = {
  long: " Section ",
  abbrev: " Sec. ",
  short: "sec",
  mr: "sec",
}.freeze

APPENDIX_DESC = {
  long: " Appendix ",
  abbrev: " App. ",
  short: "app",
  mr: "app",
}.freeze

ERRATA_DESC = {
  long: " Errata ",
  abbrev: " Err. ",
  short: "err",
  mr: "err",
}.freeze

INDEX_DESC = {
  long: " Index ",
  abbrev: " Index. ",
  short: "indx",
  mr: "indx",
}.freeze

INSERT_DESC = {
  long: " Insert ",
  abbrev: " Ins. ",
  short: "ins",
  mr: "ins",
}.freeze

module Pubid::Nist
  class Document
    attr_accessor :serie, :code, :revision, :publisher, :version, :volume,
                  :part, :addendum, :stage, :translation, :update_number,
                  :edition, :supplement, :update_year, :update_month,
                  :section, :appendix, :errata, :index, :insert

    def initialize(publisher:, serie:, docnumber:, stage: nil, supplement: nil,
                   edition_month: nil, edition_year: nil, edition_day: nil, **opts)
      @publisher = publisher
      @serie = serie
      @code = docnumber
      @stage = Stage.new(stage.to_s) if stage
      @supplement = (supplement.is_a?(Array) && "") || supplement
      @edition = parse_edition(edition_month, edition_year, edition_day) if edition_month || edition_year
      opts.each { |key, value| send("#{key}=", value.to_s) }
    end

    def parse_edition(edition_month, edition_year, edition_day)
      if edition_month
        date = Date.parse("#{edition_day || '01'}/#{edition_month}/#{edition_year}")
        if edition_day
          Edition.new(month: date.month, year: date.year, day: date.day)
        else
          Edition.new(month: date.month, year: date.year)
        end
      else
        Edition.new(year: edition_year.to_i)
      end
    end

    # returns weight based on amount of defined attributes
    def weight
      instance_variables.inject(0) do |sum, var|
        sum + (instance_variable_get(var).nil? ? 0 : 1)
      end
    end

    def ==(other)
      other.instance_variables.each do |var|
        return false if instance_variable_get(var) != other.instance_variable_get(var)
      end
      true
    end

    def merge(document)
      document.instance_variables.each do |var|
        val = document.instance_variable_get(var)
        current_val = instance_variable_get(var)
        if [:@serie, :@publisher].include?(var) ||
            (val && current_val.nil?) ||
            (val && current_val.to_s.length < val.to_s.length)
          instance_variable_set(var, val)
        end
      end

      self
    end

    def self.update_old_code(code)
      UPDATE_CODES.each do |from, to|
        code = code.gsub(from.match?(/^\/.*\/$/) ? Regexp.new(from[1..-2]) : from, to)
      end
      code
    end

    def self.parse(code)
      code = update_old_code(code)
      DocumentTransform.new.apply(DocumentParser.new.parse(code))
    rescue Parslet::ParseFailed => failure
      raise Pubid::Nist::Errors::ParseError, "#{failure.message}\ncause: #{failure.parse_failure_cause.ascii_tree}"
    end

    def to_s(format = :short)
      result = render_serie(format)
      result += " " unless format == :short || stage.nil?
      result += "#{stage&.to_s(format)}"\
                " #{code}#{render_part(format)}#{render_edition(format)}"\
                "#{render_localities(format)}"\
                "#{render_update(format)}#{render_translation(format)}"
      result = render_addendum(result, format)

      return result.gsub(" ", ".") if format == :mr

      result
    end

    def to_json(*args)
      result = {
        styles: {
          short: to_s(:short),
          abbrev: to_s(:abbrev),
          long: to_s(:long),
          mr: to_s(:mr),
        }
      }

      instance_variables.each do |var|
        val = instance_variable_get(var)
        result[var.to_s.gsub('@', '')] = val unless val.nil?
      end
      result.to_json(*args)
    end

    def render_serie(format)
      if serie.to_s(format).include?(publisher.to_s(format))
        return serie.to_s(format)
      end

      "#{publisher.to_s(format)} #{serie.to_s(format)}"
    end

    def render_part(format)
      result = ""
      result += "#{VOLUME_DESC[format]}#{volume}" unless volume.nil?
      result += "#{PART_DESC[format]}#{part}" unless part.nil?
      result
    end

    def render_edition(format)
      result = ""

      result += "#{EDITION_DESC[format]}#{edition.to_s}" unless edition.nil?
      result += "#{REVISION_DESC[format]}#{revision == '' ? '1' : revision}" if revision
      result += "#{VERSION_DESC[format]}#{version}" unless version.nil?
      result
    end

    def render_localities(format)
      result = ""
      result += "#{SUPPLEMENT_DESC[format]}#{supplement}" unless supplement.nil?
      result += "#{SECTION_DESC[format]}#{section}" unless section.nil?
      result += "#{APPENDIX_DESC[format]}" unless appendix.nil?
      result += "#{ERRATA_DESC[format]}" unless errata.nil?
      result += INDEX_DESC[format] unless index.nil?
      result += INSERT_DESC[format] unless insert.nil?

      result
    end

    def render_update(format)
      return "" if update_year.nil?

      if update_month && update_number.nil?
        @update_number = "1"
      end

      if update_year&.length == 2
        @update_year = "19#{update_year}"
      end

      if update_number.match?(/\d+/)
        update_text = update_number
        update_text += "-#{update_year}" if update_year && !update_year.empty?
        if update_month
          date = Date.parse("01/#{update_month}/#{update_year}")
          update_text += sprintf("%02d", date.month)
        end
      else
        update_text = "1"
      end

      case format
      when :long
        " Update #{update_text}"
      when :abbrev
        " Upd. #{update_text}"
      when :short
        "/Upd#{update_text}"
      when :mr
        ".u#{update_text}"
      end
    end

    def render_translation(format)
      return "" if translation.nil?

      case format
      when :long, :abbrev
        " (#{translation.upcase})"
      when :mr
        ".#{translation}"
      when :short
        "(#{translation})"
      end
    end

    def render_addendum(input, format)
      return input unless addendum

      case format
      when :long
        "Addendum to #{input}"
      when :abbrev
        "Add. to #{input}"
      when :short
        "#{input} Add."
      when :mr
        "#{input}.add-1"
      end
    end
  end
end
