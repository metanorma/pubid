# frozen_string_literal: true

require "parslet"

module Pubid
end

require "pubid-core"
require "pubid-iso"
require "pubid-iec"

require_relative "bsi/errors"
require_relative "bsi/identifier/base"
require_relative "bsi/identifier/british_standard"
require_relative "bsi/identifier/publicly_available_specification"
require_relative "bsi/identifier/published_document"
require_relative "bsi/identifier/flex"
require_relative "bsi/renderer/base"
require_relative "bsi/renderer/publicly_available_specification"
require_relative "bsi/renderer/published_document"
require_relative "bsi/renderer/flex"
require_relative "bsi/parser"
require_relative "bsi/identifier"

config = Pubid::Core::Configuration.new
config.default_type = Pubid::Bsi::Identifier::BritishStandard
config.types = [Pubid::Bsi::Identifier::BritishStandard,
                Pubid::Bsi::Identifier::Flex,
                Pubid::Bsi::Identifier::PubliclyAvailableSpecification,
                Pubid::Bsi::Identifier::PublishedDocument]
config.type_names = {
                      bs: {
                        long: "British Standard",
                        short: "BS",
                      },
                      pas: {
                        long: "Publicly Available Specification",
                        short: "PAS",
                      },
                    }.freeze
Pubid::Bsi::Identifier.set_config(config)
