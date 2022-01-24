# frozen_string_literal: true

require "yaml"
require_relative "nist_pubid/serie"
require_relative "nist_pubid/series/nist_ir"
require_relative "nist_pubid/series/nbs_hb"
require_relative "nist_pubid/series/nist_hb"
require_relative "nist_pubid/series/nbs_circ"
require_relative "nist_pubid/series/fips_pub"
require_relative "nist_pubid/series/nbs_fips"
require_relative "nist_pubid/series/nist_tn"
require_relative "nist_pubid/series/nist_sp"
require_relative "nist_pubid/series/nbs_csm"
require_relative "nist_pubid/series/nbs_mp"

SERIES_CLASSES = NistPubid::Series.constants.select do |c|
  NistPubid::Series.const_get(c).is_a?(Class)
end.map do |series_class|
  series = NistPubid::Series.const_get(series_class)
  [series.name.split("::").last.gsub!(/(.)([A-Z])/,'\1 \2').upcase, series]
end.to_h

require_relative "nist_pubid/document"
require_relative "nist_pubid/publisher"
require_relative "nist_pubid/stage"
require_relative "nist_pubid/errors"
require_relative "nist_pubid/nist_tech_pubs"
require_relative "nist_pubid/edition"
