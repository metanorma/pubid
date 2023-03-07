# frozen_string_literal: true

require "parslet"

module Pubid
end

STAGES_CONFIG = {}

require "pubid-core"

require_relative "bsi/errors"
require_relative "bsi/identifier/base"
require_relative "bsi/identifier/british_standard"
require_relative "bsi/identifier/publicly_available_specification"
require_relative "bsi/identifier/published_document"
require_relative "bsi/renderer/base"
require_relative "bsi/renderer/publicly_available_specification"
require_relative "bsi/renderer/published_document"
require_relative "bsi/parser"
require_relative "bsi/identifier"
