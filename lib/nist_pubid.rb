# frozen_string_literal: true

require "yaml"
require "parslet"
require_relative "nist_pubid/serie"
require_relative "nist_pubid/parsers/default"
require_relative "nist_pubid/document_transform"
require_relative "nist_pubid/document_parser"

Dir[File.join(__dir__, 'nist_pubid/parsers', '*.rb')].each do |file|
  require file
end

PARSERS_CLASSES = NistPubid::Parsers.constants.select do |c|
  NistPubid::Parsers.const_get(c).is_a?(Class)
end.map do |parser_class|
  parser = NistPubid::Parsers.const_get(parser_class)
  [parser.name.split("::").last.gsub(/(.)([A-Z])/, '\1 \2').upcase, parser]
end.to_h

require_relative "nist_pubid/document"
require_relative "nist_pubid/publisher"
require_relative "nist_pubid/stage"
require_relative "nist_pubid/errors"
require_relative "nist_pubid/nist_tech_pubs"
require_relative "nist_pubid/edition"
