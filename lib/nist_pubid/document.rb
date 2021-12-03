# frozen_string_literal: true

REVISION_DESC = {
  long: ', Revision ',
  abbrev: ', Revision ',
  short: 'r',
  mr: 'r'
}.freeze

VERSION_DESC = {
  long: ', Version ',
  abbrev: ', Version ',
  short: 'ver',
  mr: 'ver'
}.freeze

VOLUME_DESC = {
  long: ', Volume ',
  abbrev: ', Volume ',
  short: 'v',
  mr: 'v'
}.freeze

module NistPubid
  class Document
    attr_accessor :serie, :code, :revision, :publisher, :version, :volume

    def initialize(publisher:, series:, docnumber:, revision: nil, version: nil, volume: nil)
      @publisher = publisher
      @serie = series
      @code = docnumber
      @revision = revision
      @version = version
      @volume = volume
    end

    def self.parse(code)
      matches = {
        publisher: match(/(#{Publisher.publishers_keys.join('|')})(?=\.|\s)/, code),
        serie: match(/(#{Serie.series_keys.join('|')})(?=\.|\s)/, code)&.gsub(/\./, ' '),
        code: match(/(?<=\.|\s)[0-9-]{3,}[A-Z]?/, code),
        prt1: match(/(?<=(\.))?pt(?(1)-)[A-Z\d]+/, code),
        vol1: /(?<=(\.))?v(?(1)-)(\d+)/.match(code)&.[](2),
        ver1: match(/(?<=(\.))?ver(?(1)[-\d]|[\.\d])+/, code)&.gsub(/-/, '.'),
        rev1: /(?<=[^a-z])(?<=(\.))?r(?(1)-)(\d+)/.match(code)&.[](2),
        add1: match(/(?<=(\.))?add(?(1)-)\d+/, code),
      }
      new(publisher: matches[:publisher], series: matches[:serie], docnumber: matches[:code], revision: matches[:rev1],
          version: matches[:ver1], volume: matches[:vol1])
    end

    def self.match(regex, code)
      regex.match(code)&.to_s
    end

    def to_s(format)
      result = ""
      result += "#{Publisher.new(publisher: publisher).to_s(format)} " unless [:mr, :short].include?(format)
      result += "#{Serie.new(serie: serie).to_s(format)} #{code}"
      result += "#{REVISION_DESC[format]}#{revision}" unless revision.nil?
      result += "#{VERSION_DESC[format]}#{version}" unless version.nil?
      result += "#{VOLUME_DESC[format]}#{volume}" unless volume.nil?
      return result.gsub(' ', '.') if format == :mr

      result
    end
  end
end
