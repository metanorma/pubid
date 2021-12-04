PUBLISHERS = YAML.load_file(File.join(File.dirname(__FILE__),
                                      "../../publishers.yaml"))

module NistPubid
  class Publisher
    attr_accessor :publisher

    def initialize(publisher:)
      @publisher = publisher
    end

    def to_s(format)
      return @publisher if %i[short mr].include?(format)

      PUBLISHERS[format.to_s][@publisher]
    end

    def self.publishers_keys
      PUBLISHERS["long"].keys
    end

    def self.regexp
      /(#{PUBLISHERS["long"].keys.join('|')})(?=\.|\s)/
    end
  end
end
