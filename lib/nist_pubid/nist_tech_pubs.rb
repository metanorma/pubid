require "relaton_nist/data_fetcher"
require "nokogiri"
require "open-uri"

module NistPubid
  class NistTechPubs
    URL = "https://raw.githubusercontent.com/usnistgov/NIST-Tech-Pubs/nist-pages/xml/allrecords.xml".freeze

    def self.fetch
      Nokogiri::XML(URI.open(URL))
        .xpath("/body/query/doi_record/report-paper/report-paper_metadata")
        .map { |doc| parse_docid doc }
    rescue StandardError => e
      warn e.message
      []
    end

    def self.parse_docid(doc)
      doc.at("publisher_item/item_number", "publisher_item/identifier").text
        .sub(%r{^/}, "")
    end
  end
end
