# frozen_string_literal: true

require "parslet"

module Pubid
end

require "pubid-core"

require_relative "cen/errors"
require_relative "cen/identifier/base"
require_relative "cen/identifier/technical_specification"
require_relative "cen/identifier/technical_report"
require_relative "cen/identifier/guide"
require_relative "cen/renderer/base"
require_relative "cen/renderer/technical_specification"
require_relative "cen/renderer/technical_report"
require_relative "cen/renderer/guide"
require_relative "cen/parser"
require_relative "cen/identifier"

config = Pubid::Core::Configuration.new
config.default_type = Pubid::Cen::Identifier::Base
config.types = [Pubid::Cen::Identifier::TechnicalSpecification,
                Pubid::Cen::Identifier::TechnicalReport,
                Pubid::Cen::Identifier::Guide]
config.type_names = {}.freeze
config.stages = { "abbreviations" => { "Fpr" => [], "pr" => [] } }

Pubid::Cen::Identifier.set_config(config)
