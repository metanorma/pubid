# frozen_string_literal: true

require "parslet"
require "yaml"

module Pubid
  module Iso
    UPDATE_CODES = YAML.load_file(File.join(File.dirname(__FILE__), "../../update_codes.yaml"))
  end
end

require "pubid-core"
require_relative "iso/errors"
require_relative "iso/transformer"
require_relative "iso/identifier"
require_relative "iso/identifier/base"
require_relative "iso/identifier/international_standard"
require_relative "iso/identifier/international_standardized_profile"
require_relative "iso/identifier/technical_report"
require_relative "iso/identifier/technical_specification"
require_relative "iso/identifier/technical_committee"
require_relative "iso/identifier/supplement"
require_relative "iso/identifier/amendment"
require_relative "iso/identifier/corrigendum"
require_relative "iso/identifier/publicly_available_specification"
require_relative "iso/identifier/directives"
require_relative "iso/identifier/guide"
require_relative "iso/identifier/recommendation"
require_relative "iso/identifier/technology_trends_assessments"
require_relative "iso/identifier/international_workshop_agreement"
require_relative "iso/identifier/extract"
require_relative "iso/identifier/addendum"
require_relative "iso/identifier/data"

config = Pubid::Core::Configuration.new
config.stages = YAML.load_file(File.join(File.dirname(__FILE__), "../../stages.yaml"))
config.default_type = Pubid::Iso::Identifier::InternationalStandard
config.type_class = Pubid::Core::Type
config.types = [Pubid::Iso::Identifier::InternationalStandard,
                Pubid::Iso::Identifier::InternationalStandardizedProfile,
                Pubid::Iso::Identifier::InternationalWorkshopAgreement,
                Pubid::Iso::Identifier::Amendment,
                Pubid::Iso::Identifier::Corrigendum,
                Pubid::Iso::Identifier::PubliclyAvailableSpecification,
                Pubid::Iso::Identifier::Recommendation,
                Pubid::Iso::Identifier::Directives,
                Pubid::Iso::Identifier::Supplement,
                Pubid::Iso::Identifier::TechnicalCommittee,
                Pubid::Iso::Identifier::TechnicalReport,
                Pubid::Iso::Identifier::TechnicalSpecification,
                Pubid::Iso::Identifier::TechnologyTrendsAssessments,
                Pubid::Iso::Identifier::Guide,
                Pubid::Iso::Identifier::Extract,
                Pubid::Iso::Identifier::Addendum,
                Pubid::Iso::Identifier::Data]
config.type_names = { tr: {
                        long: "Technical Report",
                        short: "TR",
                      },
                      ts: {
                        long: "Technical Specification",
                        short: "TS",
                      },
                      is: {
                        long: "International Standard",
                        short: "IS",
                      },
                      pas: {
                        long: "Publicly Available Specification",
                        short: "PAS",
                      },
                      isp: {
                        long: "International Standardized Profiles",
                        short: "ISP",
                      },
                      guide: {
                        long: "Guide",
                        short: "Guide",
                      },
                      dir: {
                        long: "Directives",
                        short: "DIR",
                      },
                      dpas: {
                        long: "Publicly Available Specification Draft",
                        short: "DPAS",
                      },
                      cor: {
                        short: "Cor",
                      },
                      amd: {
                        short: "Amd",
                      },
                      r: {
                        long: "Recommendation",
                        short: "R",
                      } }.freeze
config.prefixes = %w[ISO ИСО FprISO]
Pubid::Iso::Identifier.set_config(config)

require_relative "iso/parser"
