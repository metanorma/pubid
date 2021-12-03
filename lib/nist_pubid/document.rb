# frozen_string_literal: true

REVISION_DESC = {
  long: ', Revision ',
  abbrev: ", Rev. ",
  short: 'r',
  mr: 'r'
}.freeze

VERSION_DESC = {
  long: ', Version ',
  abbrev: ", Ver. ",
  short: 'ver',
  mr: 'ver'
}.freeze

VOLUME_DESC = {
  long: ', Volume ',
  abbrev: ", Vol. ",
  short: 'v',
  mr: 'v'
}.freeze

PART_DESC = {
  long: " Part ",
  abbrev: " Pt. ",
  short: "pt",
  mr: "pt",
}.freeze

UPDATE_DESC = {
  long: " Update ",
  abbrev: " Upd. ",
  short: "/Upd ",
  mr: ".u",
}.freeze

module NistPubid
  class Document
    attr_accessor :serie, :code, :revision, :publisher, :version, :volume,
                  :part, :addendum, :stage, :translation, :update

    def initialize(publisher:, serie:, docnumber:, revision: nil, version: nil, volume: nil, part: nil, addendum: false,
                   stage: nil, translation: nil, update: nil)
      @publisher = Publisher.new(publisher: publisher)
      @serie = Serie.new(serie: serie)
      @code = docnumber
      @revision = revision
      @version = version
      @volume = volume
      @part = part
      @addendum = addendum
      @stage = Stage.new(stage: stage)
      @translation = translation
      @update = update
    end

    def self.parse(code)
      matches = {
        publisher: match(/(#{Publisher.publishers_keys.join('|')})(?=\.|\s)/, code),
        serie: match(/(#{Serie.series_keys.join('|')})(?=\.|\s)/, code)&.gsub(/\./, ' '),
        stage: match(/(#{Stage.stages_keys.join('|')})(?=\.|\s)/, code),
        code: match(/(?<=\.|\s)[0-9-]{3,}[A-Z]?/, code),
        prt1: /(?<=(\.))?pt(?(1)-)([A-Z\d]+)/.match(code)&.[](2),
        vol1: /(?<=(\.))?v(?(1)-)(\d+)/.match(code)&.[](2),
        ver1: match(/(?<=(\.))?ver(?(1)[-\d]|[\.\d])+/, code)&.gsub(/-/, '.'),
        rev1: /(?<=[^a-z])(?<=(\.))?r(?(1)-)(\d+)/.match(code)&.[](2),
        add1: match(/(?<=(\.))?add(?(1)-)\d+/, code),
        prt2: match(/(?<=\s)Part\s[A-Z\d]+/, code),
        vol2: match(/(?<=\s)Vol\.\s\d+/, code),
        ver2: match(/(?<=\s)Ver\.\s\d+/, code),
        rev2: match(/(?<=\s)Rev\.\s\d+/, code),
        add2: match(/(?<=\s)Addendum/, code),
        translation: match(/(?<=\()\w{3}(?=\))/, code),
        update: match(/(?<=Upd\s)([\d:]+)/, code),
      }
      new(publisher: matches[:publisher],
          serie: matches[:serie],
          docnumber: matches[:code],
          revision: matches[:rev1] || matches[:rev2],
          version: matches[:ver1] || matches[:ver2],
          volume: matches[:vol1] || matches[:vol2],
          part: matches[:prt1] || matches[:prt2],
          addendum: matches[:add1] || matches[:add2],
          stage: matches[:stage],
          update: matches[:update],
          translation: matches[:translation])
    end

    def self.match(regex, code)
      regex.match(code)&.to_s
    end

    def to_s(format)
      result = "#{render_serie(format)}#{stage.to_s(format)}"\
               "#{code}#{render_part(format)}#{render_edition(format)}"\
               "#{render_update(format)}#{render_translation(format)}"
      result = render_addendum(result, format)

      return result.gsub(' ', '.') if format == :mr

      result
    end

    def render_serie(format)
      return "#{serie.to_s(format)} " if [:mr, :short].include?(format)

      "#{publisher.to_s(format)} #{serie.to_s(format)} "
    end

    def render_part(format)
      # part, volume, addendum
      # TODO: Section, Supplement, Index, Insert, Errata
      result = ""
      result += "#{VOLUME_DESC[format]}#{volume}" unless volume.nil?
      result += "#{PART_DESC[format]}#{part}" unless part.nil?
      result
    end

    def render_edition(format)
      # TODO: edtion
      result = ""
      result += "#{REVISION_DESC[format]}#{revision}" unless revision.nil?
      result += "#{VERSION_DESC[format]}#{version}" unless version.nil?
      result
    end

    def render_update(format)
      return "" if update.nil?

      result = "#{UPDATE_DESC[format]}#{update}"

      return result.gsub(":", "-") if format == :mr

      result
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
