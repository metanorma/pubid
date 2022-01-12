# frozen_string_literal: true
require "json"

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

module NistPubid
  class Document
    attr_accessor :serie, :code, :revision, :publisher, :version, :volume,
                  :part, :addendum, :stage, :translation, :update_number,
                  :edition, :supplement, :update_year, :section, :appendix,
                  :errata, :index, :insert

    def initialize(publisher:, serie:, docnumber:, **opts)
      @publisher = publisher
      @serie = Serie.new(serie: serie)
      @code = docnumber
      opts.each { |key, value| send("#{key}=", value) }
    end

    # returns weight based on amount of defined attributes
    def weight
      instance_variables.inject(0) do |sum, var|
        sum + (instance_variable_get(var).nil? ? 0 : 1)
      end
    end

    def merge(document)
      document.instance_variables.each do |var|
        val = document.instance_variable_get(var)
        instance_variable_set(var, val) unless val.nil?
      end

      self
    end

    def self.update_old_code(code)
      code = code.gsub("NIST FIPS", "NIST FIPS PUB") unless code.include?("NIST FIPS PUB")
      code.gsub("NBS MONO", "NBS MN").gsub("NIST MONO", "NIST MN")
        .gsub("NIST MP", "NBS MP")
        .gsub("NIST SP 304a-2017", "NIST SP 304A-2017")
        .gsub("NIST SP 260-162 2006ed.", "NIST SP 260-162e2006")
        .gsub("NBS CIRC 154suprev", "NBS CIRC 154r1sup")
        .gsub("NIST SP 260-126 rev 2013", "NIST SP 260-126r2013")
        .gsub("NIST CSWP", "NIST CSRC White Paper")
        .gsub("NIST SP 800-56ar", "NIST SP 800-56Ar1")
        .gsub("NIST.LCIRC", "NIST.LC")
        .gsub("NBS.LCIRC", "NBS.LC")
        .gsub("NISTIR", "NIST IR")
        .gsub("NIST.CSWP.01162020pt", "NIST.CSWP.01162020(por)")
        .gsub("NBS FIPS PUB 11-1-Sep30", "NBS FIPS PUB 11-1-Sep30/1977")
        .gsub(/(?<=NBS MP )(\d+)\((\d+)\)/, '\1e\2')
        .gsub(/(?<=\d)es/, "(spa)")
        .gsub(/(?<=\d)chi/, "(zho)")
        .gsub(/(?<=\d)viet/, "(vie)")
        .gsub(/(?<=\d)port/, "(por)")
        .gsub(/(?<=\d)(pt)(?!\d)/, "(por)")
        .gsub(/(?<=\d)id/, "(ind)")
    end

    def self.parse(code)
      code = update_old_code(code)
      matches = {
        publisher: Publisher.parse(code),
        stage: Stage.parse(code),
        part: /(?<=(\.))?(?<![a-z])+(?:pt|Pt|p)(?(1)-)([A-Z\d]+)/.match(code)
                &.[](2),
        version:
          /(?<=\.)?(?:(?:ver)((?(1)[-\d]|[.\d])+|\d+)|(?:v)(\d+\.[.\d]+))/
            .match(code).to_a[1..-1]&.compact&.first&.gsub(/-/, "."),
        revision: /(?:[\daA-Z](?:r|Rev\.\s|([0-9]+[A-Za-z]*-[0-9]+[A-Za-z]*-))|, Revision )([\da]+)/
          .match(code)&.[](2),
        addendum: match(/(?<=(\.))?(add(?:-\d+)?|Addendum)/, code),
        edition: /(?<=[^a-z])(?<=\.)?(?:e(?(1)-)|Ed\.\s|Edition\s)(\d+)|
                  NBS\sFIPS\s[0-9]+[A-Za-z]*-[0-9]+[A-Za-z]*-([A-Za-z\d]+)
          /x.match(code)&.captures&.join,
        section: /(?<=sec)\d+/.match(code)&.to_s,
        appendix: /\d+app/.match(code)&.to_s,
        errata: /-errata|\d+err(?:ata)?/.match(code)&.to_s,
        index: /\d+index|\d+indx/.match(code)&.to_s,
        insert: /\d+ins(?:ert)?/.match(code)&.to_s
      }

      matches[:serie] = Serie.parse(matches[:publisher], code)
      edition = /(?<=[^a-z])(?<=\.)?(?:e(?(1)-)|Ed\.\s)(\d+)/x.match(code)
      if edition
        edition_to_remove = edition.to_s
      else
        edition = /NBS\sFIPS\s[0-9]+[A-Za-z]*-[0-9]+[A-Za-z]*-([A-Za-z\d]+)|
         NBS\sFIPS\s[0-9]+[A-Za-z]*-([A-Za-z0-9]+)
          /x.match(code)
        edition_to_remove = "-#{edition.captures.join}" if edition
      end

      if edition
        code.gsub!(edition_to_remove, "")
        matches[:edition] = edition.captures.join
      end
      matches[:edition] = Edition.parse(code)

      code.gsub!(matches[:edition].parsed, "") if matches[:edition]

      matches[:revision] = /(?:[\daA-Z](?:r|Rev\.\s|([0-9]+[A-Za-z]*-[0-9]+[A-Za-z]*-))|, Revision )([\da]+)/
        .match(code)&.[](2)

      supplement = /(?:(?:supp?)-?(\d*)|Supplement|Suppl.)/
        .match(code)
      unless supplement.nil?
        matches[:supplement] = supplement[1].nil? ? "" : supplement[1]
      end

      update = code.scan(/((?<=Upd|Update )\s?[\d:]+|-upd)-?(\d*)/).first

      (matches[:update_number], matches[:update_year]) = update if update

      unless matches[:serie]
        raise Errors::ParseError.new("failed to parse serie for #{code}")
      end

      unless matches[:stage].nil?
        code = code.gsub(matches[:stage].original_code, "")
      end

      unless ["NBS CSM", "NBS CS"].include?(matches[:serie].to_s)
        matches[:volume] = /(?<=(\.))?v(?(1)-)(\d+)(?!\.\d+)/.match(code)&.[](2)
      end

      matches[:revision] = nil if matches[:addendum]

      matches[:docnumber] = parse_docnumber(matches[:serie].parsed, code)

      # NIST GCR documents often have a 3-part identifier -- the last part is
      # not revision but is part of the identifier.
      if matches[:serie].to_s == "NIST GCR" && matches[:revision]
        matches[:docnumber] += "-#{matches[:revision]}"
        matches[:revision] = nil
      end

      matches[:serie] = SERIES["mr"].invert[matches[:serie].to_s] || matches[:serie].to_s
      # matches[:serie].gsub!(/\./, " ")
      matches[:translation] = match(/(?<=\()\w{3}(?=\))/, code)

      new(**matches)
    end

    def self.parse_docnumber(serie, code)
      localities = "[Pp]t\\d+|r(?:\\d+|[A-Za-z]?)|e\\d+|p|v|sec\\d+|inde?x|err(?:ata)?|ins(?:ert)|app|ins?"
      excluded_parts = "(?!#{localities}|supp?)"

      if ["NBS CSM", "NBS CS"].include?(serie)
        docnumber = /v(\d+)n(\d+)/.match(code).to_a[1..-1]&.join("-")
      else
        # match docnumbers with localities in the first part, like NBS CIRC 11e2-1915
        docnumber =
          /(?:#{serie.gsub(" ", "(?:\s|\.)")})(?:\s|\.)?([0-9]+)(?:#{localities})(-[0-9]+)?/
            .match(code)&.captures&.join

        docnumber ||=
          /(?:#{serie.gsub(" ", "(?:\s|\.)")})(?:\s|\.)? # match serie
           ([0-9]+ # first part of report number
             (?:#{excluded_parts}[A-Za-z]+)? # with letter but without localities
             (?:-m)? # for NBS CRPL 4-m-5
             (?:-[A-Za]+)? # for NIST SP 1075-NCNR, NIST SP 1113-BFRL, NIST IR 6529-a
             (?:-[0-9.]+)? # second part
             (?:
               (?: # only big letter
                 (#{excluded_parts}[A-Z]|(?![a-z]))+|#{excluded_parts}[a-z]?|#{excluded_parts}[a-z]+
               )? # or small letter but without localities
             )
           )/x
            .match(code)&.[](1)&.upcase
      end

      unless docnumber
        raise Errors::ParseError.new(
          "failed to parse document identifier for #{code}",
        )
      end

      docnumber
    end

    def self.match(regex, code)
      regex.match(code)&.to_s
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

      result += "#{REVISION_DESC[format]}#{revision.to_s.upcase}" if revision
      result += "#{VERSION_DESC[format]}#{version}" unless version.nil?
      result += "#{EDITION_DESC[format]}#{edition.to_s}" unless edition.nil?
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

      if update_number.match?(/\d+/)
        update_text = update_number
        update_text += "-#{update_year}" if update_year
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
