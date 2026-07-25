# frozen_string_literal: true

# The IHO flavor base class is Pubid::Iho::Identifier — a real Pubid::Identifier
# subclass that every concrete IHO identifier descends from, so `is_a?` identity
# and the shared polymorphic `from_hash` work natively (no facade needed). Its
# body and `.parse` live in identifiers/base.rb; this file just ensures it is loaded when a consumer
# references Pubid::Iho::Identifier directly.
