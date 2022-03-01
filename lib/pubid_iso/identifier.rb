require "algolia"

module PubidIso
  class Identifier
    attr_accessor :number, :copublisher, :stage, :part

    def initialize(**opts)
      opts.each { |key, value| send("#{key}=", value.to_s) }
      # @number = number
      # @url = fetch_iso.first[:path]
    end

    def urn
      URN.new(self)
    end

    def self.parse(code)
      new(**Parser.new.parse(code))
    rescue Parslet::ParseFailed => failure
      raise PubidIso::Errors::ParseError, "#{failure.message}\ncause: #{failure.parse_failure_cause.ascii_tree}"
    end

    def fetch_iso # rubocop:disable Metrics/AbcSize,Metrics/MethodLength
      # %r{\s(?<num>\d+)(?:-(?<part>[\d-]+))?} =~ text
      # http = Net::HTTP.new "www.iso.org", 443
      # http.use_ssl = true
      # search = ["status=ENT_ACTIVE,ENT_PROGRESS,ENT_INACTIVE,ENT_DELETED"]
      # search << "docNumber=#{num}"
      # search << "docPartNo=#{part}" if part
      # q = search.join "&"
      # resp = http.get("/cms/render/live/en/sites/isoorg.advancedSearch.do?#{q}",
      #                 "Accept" => "application/json, text/plain, */*")
      config = Algolia::Search::Config.new(application_id: "JCL49WV5AR", api_key: "dd1b9e1ab383f4d4817d29cd5e96d3f0")
      client = Algolia::Search::Client.new config, logger: ::Logger.new($stderr)
      index = client.init_index "all_en"
      resp = index.search code, hitsPerPage: 100, filters: "category:standard"
      # return [] if resp.body.empty?

      # json = JSON.parse resp.body
      # json["standards"]
      resp[:hits].sort! do |a, b|
        if sort_weight(a[:status]) == sort_weight(b[:status]) && b[:year] = a[:year]
          a[:title] <=> b[:title]
        elsif sort_weight(a[:status]) == sort_weight(b[:status])
          b[:year] - a[:year]
        else
          sort_weight(a[:status]) - sort_weight(b[:status])
        end
      end
    end

    def sort_weight(status)
      case status # && hit["publicationStatus"]["key"]
      when "Published" then 0
      when "Under development" then 1
      when "Withdrawn" then 2
      when "Deleted" then 3
      else 4
      end
    end
  end
end
