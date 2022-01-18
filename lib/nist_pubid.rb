# frozen_string_literal: true

require "yaml"
REGEXPS = YAML.load_file(File.join(File.dirname(__FILE__), "../regexps.yaml"))

require_relative "nist_pubid/document"
require_relative "nist_pubid/publisher"
require_relative "nist_pubid/serie"
require_relative "nist_pubid/stage"
require_relative "nist_pubid/errors"
require_relative "nist_pubid/nist_tech_pubs"
require_relative "nist_pubid/edition"
