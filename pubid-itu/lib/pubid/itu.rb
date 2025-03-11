# frozen_string_literal: true

require "parslet"
require "yaml"

module Pubid
  module Itu
    LANGUAGES = {
      "ru": "R",
      "fr": "F",
      "en": "E",
      "ar": "A",
      "es": "S",
      "zh": "C",
    }.freeze

    I18N = YAML.load_file(File.join(File.dirname(__FILE__), "../../i18n.yaml"))
  end
end

require "pubid-core"

require_relative "itu/errors"
require_relative "itu/identifier/base"
require_relative "itu/identifier/recommendation"
require_relative "itu/identifier/question"
require_relative "itu/identifier/resolution"
require_relative "itu/identifier/special_publication"
require_relative "itu/identifier/supplement"
require_relative "itu/identifier/amendment"
require_relative "itu/identifier/regulatory_publication"
require_relative "itu/identifier/implementers_guide"
require_relative "itu/identifier/annex"
require_relative "itu/identifier/corrigendum"
require_relative "itu/identifier/addendum"
require_relative "itu/identifier/appendix"
require_relative "itu/identifier/contribution"
require_relative "itu/transformer"
require_relative "itu/renderer/base"
require_relative "itu/renderer/implementers_guide"
require_relative "itu/renderer/contribution"
require_relative "itu/parser"
require_relative "itu/identifier"
require_relative "itu/configuration"

config = Pubid::Itu::Configuration.new
config.default_type = Pubid::Itu::Identifier::Base
config.types = [Pubid::Itu::Identifier::Base,
                Pubid::Itu::Identifier::Recommendation,
                Pubid::Itu::Identifier::Resolution,
                Pubid::Itu::Identifier::Question,
                Pubid::Itu::Identifier::SpecialPublication,
                Pubid::Itu::Identifier::Amendment,
                Pubid::Itu::Identifier::Corrigendum,
                Pubid::Itu::Identifier::RegulatoryPublication,
                Pubid::Itu::Identifier::ImplementersGuide,
                Pubid::Itu::Identifier::Supplement,
                Pubid::Itu::Identifier::Annex,
                Pubid::Itu::Identifier::Addendum,
                Pubid::Itu::Identifier::Appendix,
                Pubid::Itu::Identifier::Contribution]
config.type_names = {}.freeze
config.series = YAML.load_file(File.join(File.dirname(__FILE__), "../../series.yaml"))
Pubid::Itu::Identifier.set_config(config)
