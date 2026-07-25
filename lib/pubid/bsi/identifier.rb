# frozen_string_literal: true

# Pubid::Bsi::Identifier is the BSI base class (a real Pubid::Identifier
# subclass); its body, `.parse` (including the IEC-delegation logic), and the
# SingleIdentifier back-compat alias live in single_identifier.rb. This file
# just ensures it is loaded when a consumer references Pubid::Bsi::Identifier.
