# frozen_string_literal: true

require "parslet"
require "yaml"

module Pubid
  module Ccsds
    UPDATE_CODES = YAML.load_file(File.join(File.dirname(__FILE__), "../../update_codes.yaml"))
  end
end


require "pubid-core"

require_relative "ccsds/identifier/base"
require_relative "ccsds/identifier/corrigendum"
require_relative "ccsds/renderer/base"
require_relative "ccsds/renderer/corrigendum"
require_relative "ccsds/parser"
require_relative "ccsds/identifier"

config = Pubid::Core::Configuration.new
config.default_type = Pubid::Ccsds::Identifier::Base
config.types = [Pubid::Ccsds::Identifier::Base,
                Pubid::Ccsds::Identifier::Corrigendum]
config.type_names = {}.freeze
Pubid::Ccsds::Identifier.set_config(config)
