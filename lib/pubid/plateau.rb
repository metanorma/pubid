# frozen_string_literal: true

require "parslet"
require "yaml"

module Pubid
  module Plateau
    UPDATE_CODES = YAML.load_file(File.join(File.dirname(__FILE__), "../../update_codes.yaml"))
  end
end

require "pubid-core"

require_relative "plateau/identifier"
require_relative "plateau/identifier/base"
require_relative "plateau/identifier/handbook"
require_relative "plateau/identifier/technical_report"
require_relative "plateau/renderer/base"
require_relative "plateau/renderer/handbook"
require_relative "plateau/renderer/technical_report"

config = Pubid::Core::Configuration.new
config.default_type = Pubid::Plateau::Identifier::Base
config.types = [Pubid::Plateau::Identifier::Handbook,
                Pubid::Plateau::Identifier::TechnicalReport]

Pubid::Plateau::Identifier.set_config(config)

require_relative "plateau/parser"
