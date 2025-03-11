# frozen_string_literal: true

require "parslet"

module Pubid
end

require "pubid-core"
require "pubid-iso"
require "pubid-iec"
require "pubid-cen"

require_relative "bsi/errors"
require_relative "bsi/transformer"
require_relative "bsi/identifier/base"
require_relative "bsi/identifier/british_standard"
require_relative "bsi/identifier/publicly_available_specification"
require_relative "bsi/identifier/published_document"
require_relative "bsi/identifier/draft_document"
require_relative "bsi/identifier/flex"
require_relative "bsi/identifier/amendment"
require_relative "bsi/identifier/corrigendum"
require_relative "bsi/identifier/national_annex"
require_relative "bsi/identifier/expert_commentary"
require_relative "bsi/identifier/collection"
require_relative "bsi/renderer/base"
require_relative "bsi/renderer/publicly_available_specification"
require_relative "bsi/renderer/published_document"
require_relative "bsi/renderer/draft_document"
require_relative "bsi/renderer/flex"
require_relative "bsi/renderer/amendment"
require_relative "bsi/renderer/corrigendum"
require_relative "bsi/renderer/national_annex"
require_relative "bsi/renderer/expert_commentary"
require_relative "bsi/renderer/collection"
require_relative "bsi/parser"
require_relative "bsi/identifier"

config = Pubid::Core::Configuration.new
config.default_type = Pubid::Bsi::Identifier::BritishStandard
config.types = [Pubid::Bsi::Identifier::BritishStandard,
                Pubid::Bsi::Identifier::Flex,
                Pubid::Bsi::Identifier::PubliclyAvailableSpecification,
                Pubid::Bsi::Identifier::PublishedDocument,
                Pubid::Bsi::Identifier::DraftDocument,
                Pubid::Bsi::Identifier::Amendment,
                Pubid::Bsi::Identifier::Corrigendum,
                Pubid::Bsi::Identifier::NationalAnnex,
                Pubid::Bsi::Identifier::ExpertCommentary,
                Pubid::Bsi::Identifier::Collection]
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
config.prefixes = ["BS", "PAS", "PD", "DD", "Flex", "BSI"]
Pubid::Bsi::Identifier.set_config(config)
