# frozen_string_literal: true

module Pubid
  # Core module for shared functionality across all flavors.
  module Core
    autoload :UpdateCodes, "#{__dir__}/core/update_codes"
    autoload :PatternDocGenerator, "#{__dir__}/core/pattern_doc_generator"
  end
end
