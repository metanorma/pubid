module NistPubid
  class Publisher
    attr_accessor :publisher

    def initialize(publisher:)
      @publisher = publisher
    end

    def to_s(format)
      return @publisher if format == :short || format == :mr

      self.class.publishers[format.to_s][@publisher]
    end

    def self.publishers
      @publishers ||= YAML.load_file(File.join(File.dirname(__FILE__), "../../publishers.yaml"))
    end

    def self.publishers_keys
      publishers["long"].keys
    end
  end
end
