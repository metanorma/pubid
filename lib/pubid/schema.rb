# frozen_string_literal: true

require "yaml"

module Pubid
  # Single source of truth declarations (schema/ directory). TODO 03 of the
  # SSOT restructure: loader and value objects. TODO 04-07 make the runtime
  # a consumer of these declarations (registry bridge, prefixes, metadata).
  module Schema
    autoload :Error, "pubid/schema/error"
    autoload :NotFoundError, "pubid/schema/error"
    autoload :InvalidError, "pubid/schema/error"
    autoload :TypedStage, "pubid/schema/typed_stage"
    autoload :IdentifierType, "pubid/schema/identifier_type"
    autoload :Declaration, "pubid/schema/declaration"
    autoload :Loader, "pubid/schema/loader"

    class << self
      # Pubid::Schema.for("iso") => frozen Pubid::Schema::Declaration
      def for(flavor)
        Loader.for(flavor)
      end
    end
  end
end
