# frozen_string_literal: true

# The NIST flavor base class is Pubid::Nist::Identifier — a real
# Pubid::Identifier subclass that every concrete NIST identifier descends from,
# so `id.is_a?(Pubid::Nist::Identifier)` and the shared polymorphic `from_hash`
# work natively (no facade needed). Its full body and `.parse` are defined in identifiers/base.rb to keep
# that large body in one place; this file just ensures it is loaded when a
# consumer references Pubid::Nist::Identifier directly.
