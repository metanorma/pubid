# frozen_string_literal: true

# The ASHRAE flavor base class is Pubid::Ashrae::Identifier — a real
# Pubid::Identifier subclass that every concrete ASHRAE identifier descends
# from, so `is_a?` identity and the shared polymorphic `from_hash` work natively
# (no facade needed). Its body and `.parse` live in identifiers/base.rb; this
# file just ensures it is loaded when a consumer references
# Pubid::Ashrae::Identifier directly.
