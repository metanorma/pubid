# frozen_string_literal: true

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

module NistPubid
  class Document
    attr_accessor :serie, :code, :revision, :publisher, :version, :volume,
                  :part, :addendum, :stage, :translation, :update_number,
                  :edition, :supplement, :update_year

    def initialize(publisher:, serie:, docnumber:, **opts)
      @publisher = Publisher.new(publisher: publisher)
      @serie = Serie.new(serie: serie)
      @code = docnumber
      opts.each { |key, value| send("#{key}=", value) }
    end

    def self.update_old_code(code)
      code = code.gsub("FIPS", "FIPS PUB") unless code.include?("FIPS PUB")
      code.gsub("NBS MONO", "NBS MN").gsub("NIST MONO", "NIST MN")
        .gsub("NIST MP", "NBS MP")
        .gsub("NIST SP 304a-2017", "NIST SP 304A-2017")
        .gsub("NIST SP 260-162 2006ed.", "NIST SP 260-162e2006")
        .gsub(/(?<=\d)es/, "(spa)")
        .gsub(/(?<=\d)chi/, "(zho)")
        .gsub(/(?<=\d)viet/, "(vie)")
        .gsub(/(?<=\d)port/, "(por)")
        .gsub(/^LCIRC/, "NBS LC")
    end

    def self.parse(code)
      code = update_old_code(code)
      matches = {
        publisher: match(Publisher.regexp, code) || "NIST",
        serie: match(Serie.regexp, code),
        stage: Stage.parse(code),
        part: /(?<=(\.))?(?<![a-z])+(?:pt|p)(?(1)-)([A-Z\d]+)/.match(code)
                &.[](2),
        volume: /(?<=(\.))?v(?(1)-)(\d+)(?!\.\d+)/.match(code)&.[](2),
        version:
          /(?<=\.)?(?:(?:ver)((?(1)[-\d]|[.\d])+|\d+)|(?:v)(\d+\.[.\d]+))/
            .match(code).to_a[1..-1]&.compact&.first&.gsub(/-/, "."),
        revision: /\d(?:r|Rev\.\s|([0-9]+[A-Za-z]*-[0-9]+[A-Za-z]*-))([\da]+)/
          .match(code)&.[](2),
        addendum: match(/(?<=(\.))?(add(?(1)-)\d+|Addendum)/, code),
        edition: /(?<=[^a-z])(?<=(\.))?(?:e(?(1)-)|Ed\.\s)(\d+)/
          .match(code)&.[](2),
      }
      supplement = /(?<=\.)?(?:(?:supp?)(?(1)-)(\d*)|Supplement|Suppl.)/
        .match(code)
      unless supplement.nil?
        matches[:supplement] = supplement[1].nil? ? "" : supplement[1]
      end

      update = code.scan(/((?<=Upd)\s?[\d:]+|-upd)-?(\d*)/).first

      (matches[:update_number], matches[:update_year]) = update if update

      unless matches[:serie]
        raise Errors::ParseError.new("failed to parse serie for #{code}")
      end

      unless matches[:stage].nil?
        code = code.gsub(matches[:stage].original_code, "")
      end

      if ["NBS CSM", "NBS CS"].include?(matches[:serie])
        matches[:docnumber] = /v(\d+)n(\d+)/.match(code).to_a[1..-1]&.join("-")
        matches[:volume] = nil
      else
        excluded_parts = "(?!pt|r\\d+|e\\d+|p|v|supp?)"
        matches[:docnumber] =
          /(?:#{matches[:serie]})(?:\s|\.)?([0-9]+(?:#{excluded_parts}[A-Za-z]+)?(?:-[0-9]+)?(?:(?:([A-Z]|(?![a-z]))+|#{excluded_parts}[a-z]+)?))/
            .match(code)&.[](1)&.upcase
      end

      unless matches[:docnumber]
        raise Errors::ParseError.new(
          "failed to parse document identifier for #{code}",
        )
      end

      matches[:serie].gsub!(/\./, " ")
      matches[:translation] = match(/(?<=\()\w{3}(?=\))/, code)

      new(**matches)
    end

    def self.match(regex, code)
      regex.match(code)&.to_s
    end

    def to_s(format)
      result = render_serie(format)
      result += " " unless format == :short || stage.nil?
      result += "#{stage&.to_s(format)}"\
                " #{code}#{render_part(format)}#{render_edition(format)}"\
                "#{render_update(format)}#{render_translation(format)}"
      result = render_addendum(result, format)

      return result.gsub(" ", ".") if format == :mr

      result
    end

    def render_serie(format)
      if serie.to_s(format).include?(publisher.to_s(format))
        return serie.to_s(format)
      end

      "#{publisher.to_s(format)} #{serie.to_s(format)}"
    end

    def render_part(format)
      # TODO: Section, Index, Insert, Errata
      result = ""
      result += "#{VOLUME_DESC[format]}#{volume}" unless volume.nil?
      result += "#{PART_DESC[format]}#{part}" unless part.nil?
      result += "#{SUPPLEMENT_DESC[format]}#{supplement}" unless supplement.nil?
      result
    end

    def render_edition(format)
      result = ""
      if revision
        result += if %i[long abbrev].include?(format) ||
            [volume, part, supplement, version, edition].any?
                    "#{REVISION_DESC[format]}#{revision}"
                  else
                    "-#{revision}"
                  end
      end
      result += "#{VERSION_DESC[format]}#{version}" unless version.nil?
      result += "#{EDITION_DESC[format]}#{edition}" unless edition.nil?
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
      else
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
        "#{input} Addendum"
      when :mr
        "#{input}.add-1"
      end
    end
  end
end
