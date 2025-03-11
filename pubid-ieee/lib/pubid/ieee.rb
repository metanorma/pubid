require "parslet"

module Pubid
  module Ieee

  end
end

require_relative "ieee/errors"
require_relative "ieee/parser"
require_relative "ieee/transformer"
require_relative "ieee/type"
require_relative "ieee/renderer/base"
require_relative "ieee/identifier"
require_relative "ieee/identifier/base"

config = Pubid::Core::Configuration.new
config.default_type = Pubid::Ieee::Identifier::Base
config.types = [Pubid::Ieee::Identifier::Base]
Pubid::Ieee::Identifier.set_config(config)
