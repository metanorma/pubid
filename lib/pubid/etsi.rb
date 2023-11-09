# frozen_string_literal: true

require "parslet"
require "yaml"

module Pubid
  module Etsi

  end
end


require "pubid-core"

require_relative "etsi/identifier"
require_relative "etsi/identifier/base"
require_relative "etsi/renderer/base"

config = Pubid::Core::Configuration.new
# config.default_type = Pubid::Ccsds::Identifier::Base
# config.types = [Pubid::Ccsds::Identifier::Base,
#                 Pubid::Ccsds::Identifier::Corrigendum]
# config.type_names = {}.freeze
# Pubid::Ccsds::Identifier.set_config(config)
# EN "European Standard"
# ES "ETSI Standard"
# EG "ETSI Guide"
# TS "Technical Specification"
# (deprecated) ETR "European telecommunications report"
# (deprecated) ETS "European telecommunications standard"
# (deprecated) I-ETS: Provisional ETS
# TBR "Technical Basis for Regulation"
# (deprecated) TCRTR "Technical Committee Report - Technical Report"
# (deprecated) NET "Norme Européenne de Télécommunication" / "Technical
# GR "Group Report"
# GS "Group Specification"
# SR "Special Report"

config.type_names = {
  en: {
    long: "European Standard",
    short: "EN",
  },
  es: {
    long: "ETSI Standard",
    short: "ES",
  },
  eg: {
    long: "ETSI Guide",
    short: "EG",
  },
  ts: {
    long: "Technical Specification",
    short: "TS",
  },
  etr: {
    long: "European telecommunications report",
    short: "ETR",
  },
  ets: {
    long: "European telecommunications standard",
    short: "ETS",
  },
  iets: {
    long: "Provisional ETS",
    short: "I-ETS",
  },
  tbr: {
    long: "Technical Basis for Regulation",
    short: "TBR",
  },
  tcrtr: {
    long: "Technical Committee Report - Technical Report",
    short: "TCRTR",
  },
  net: {
    long: "Norme Européenne de Télécommunication",
    short: "NET",
  },
  gr: {
    long: "Group Report",
    short: "GR",
  },
  gs: {
    long: "Group Specification",
    short: "GS",
  },
  sr: {
    long: "Special Report",
    short: "SR",
  },
  tr: {
    long: "Technical Report",
    short: "TR",
  },
  gts: {
    long: "GSM Technical Specification",
    short: "GTS",
  }
}
Pubid::Etsi::Identifier.set_config(config)

require_relative "etsi/parser"
