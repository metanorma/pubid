# frozen_string_literal: true

require "parslet"

module Pubid
end

STAGES_CONFIG = {}

require "pubid-core"

require_relative "bsi/identifier/base"
require_relative "bsi/renderer/base"
require_relative "bsi/parser"
require_relative "bsi/identifier"
