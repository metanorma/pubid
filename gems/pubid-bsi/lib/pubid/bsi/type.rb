module Pubid::Bsi
  class Type < Pubid::Core::Type

    DEFAULT_TYPE = :bs

    TYPE_NAMES = {
      bs: {
        long: "British Standard",
        short: "BS",
      },
      pas: {
        long: "Publicly Available Specification",
        short: "PAS",
      },
    }.freeze
  end
end
