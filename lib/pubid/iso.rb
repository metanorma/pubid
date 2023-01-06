# frozen_string_literal: true

require "parslet"
require "yaml"

module Pubid
  module Iso

  end
end

STAGES_CONFIG = YAML.load_file(File.join(File.dirname(__FILE__), "../../stages.yaml"))

require "pubid-core"
require_relative "iso/errors"
require_relative "iso/stage"
require_relative "iso/type"
require_relative "iso/harmonized_stage_code"
require_relative "iso/transformer"
require_relative "iso/identifier"
require_relative "iso/identifier/base"
require_relative "iso/identifier/international_standard"
require_relative "iso/identifier/international_standardized_profile"
require_relative "iso/identifier/technical_report"
require_relative "iso/identifier/technical_specification"
require_relative "iso/identifier/technical_committee"
require_relative "iso/identifier/supplement"
require_relative "iso/identifier/amendment"
require_relative "iso/identifier/corrigendum"
require_relative "iso/identifier/publicly_available_specification"
require_relative "iso/identifier/directives"
require_relative "iso/identifier/guide"
require_relative "iso/identifier/recommendation"
require_relative "iso/identifier/technology_trends_assessments"
require_relative "iso/identifier/international_workshop_agreement"
require_relative "iso/parser"
