# frozen_string_literal: true

SERIE_DESC = {
  long: { 'SP': 'Special Publication' },
  abbrev: { 'SP': 'Spec. Publ.' },
  short: { 'SP': 'SP' },
  mr: { 'SP': 'SP' }
}.freeze

PUBLISHER_DESC = {
  long: 'National Institute of Standards and Technology',
  abbrev: 'Natl. Inst. Stand. Technol.',
  short: 'NIST',
  mr: 'NIST'
}.freeze

REVISION_DESC = {
  long: ', Revision ',
  abbrev: ', Revision ',
  short: 'r',
  mr: 'r'
}.freeze

class NistPubid
  attr_accessor :serie, :code, :revision, :publisher

  def initialize(publisher:, series:, docnumber:, revision:)
    @publisher = publisher
    @serie = series
    @code = docnumber
    @revision = revision
  end

  def self.parse(code)
    matches = {
      serie: match(/(SP|FIPS|(NIST)?IR|ITL\sBulletin|White\sPaper)(?=\.|\s)/, code),
      code: match(/(?<=\.|\s)[0-9-]{3,}[A-Z]?/, code),
      prt1: match(/(?<=(\.))?pt(?(1)-)[A-Z\d]+/, code),
      vol1: match(/(?<=(\.))?v(?(1)-)\d+/, code),
      ver1: match(/(?<=(\.))?ver(?(1)[-\d]|[\.\d])+/, code)&.gsub(/-/, '.'),
      rev1: match(/(?<=[^a-z])(?<=(\.))?r(?(1)-)\d+/, code),
      add1: match(/(?<=(\.))?add(?(1)-)\d+/, code),
    }
    new(publisher: :nist, series: matches[:serie], docnumber: matches[:code], revision: matches[:rev1].gsub('r', ''))
  end

  def self.match(regex, code)
    regex.match(code)&.to_s
  end

  def to_s(format)
    result = "#{PUBLISHER_DESC[format]} #{SERIE_DESC[format][serie.to_sym]} #{code}"
    result += "#{REVISION_DESC[format]}#{revision}" unless revision.nil?
    return result.gsub(' ', '.') if format == :mr

    result
  end
end
