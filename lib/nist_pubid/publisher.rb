PUBLISHERS = YAML.load_file(File.join(File.dirname(__FILE__),
                                      "../../publishers.yaml"))

module NistPubid
  class Publisher
    attr_accessor :publisher

    def initialize(publisher:)
      @publisher = publisher
    end

    def to_s(format = :short)
      return @publisher if %i[short mr].include?(format)

      PUBLISHERS[format.to_s][@publisher]
    end

    def ==(other)
      other.publisher == @publisher
    end

    def self.publishers_keys
      PUBLISHERS["long"].keys
    end

    def self.parse(code)
      publisher = /(#{PUBLISHERS["long"].keys.join('|')})(?=\.|\s)/.match(code)
      return new(publisher: publisher.to_s) if publisher

      publisher = /(#{PUBLISHERS["long"].values.join('|')})(?=\.|\s)/.match(code)
      return new(publisher: PUBLISHERS["long"].key(publisher.to_s)) if publisher

      publisher = /(#{PUBLISHERS["abbrev"].values.join('|')})(?=\.|\s)/.match(code)
      return new(publisher: PUBLISHERS["abbrev"].key(publisher.to_s)) if publisher

      new(publisher: "NIST")
    end

    def self.regexp
      /(#{PUBLISHERS["long"].keys.join('|')})(?=\.|\s)/
    end
  end
end
