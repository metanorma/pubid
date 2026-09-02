# frozen_string_literal: true

module Pubid
  module Schema
    # Base error for schema loading and lookup failures.
    class Error < StandardError; end

    # Raised when a flavor declaration file cannot be found.
    class NotFoundError < Error; end

    # Raised when a declaration file violates the format contract.
    class InvalidError < Error; end
  end
end
