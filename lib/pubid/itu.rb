# frozen_string_literal: true

require "parslet"
require "yaml"

module Pubid
  module Itu

  end
end

require "pubid-core"

require_relative "itu/errors"
require_relative "itu/identifier/base"
require_relative "itu/identifier/recommendation"
require_relative "itu/renderer/base"
require_relative "itu/parser"
require_relative "itu/identifier"
require_relative "itu/configuration"

config = Pubid::Itu::Configuration.new
config.default_type = Pubid::Itu::Identifier::Base
config.types = [Pubid::Itu::Identifier::Base,
                Pubid::Itu::Identifier::Recommendation]
config.type_names = {}.freeze
config.series = YAML.load_file(File.join(File.dirname(__FILE__), "../../series.yaml"))
Pubid::Itu::Identifier.set_config(config)
