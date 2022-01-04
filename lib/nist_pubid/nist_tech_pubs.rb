require "relaton_nist/data_fetcher"
require "nokogiri"
require "open-uri"

module NistPubid
  class NistTechPubs
    URL = "https://raw.githubusercontent.com/usnistgov/NIST-Tech-Pubs/nist-pages/xml/allrecords.xml".freeze

    @converted_id = @converted_doi = {}

    class << self

      attr_accessor :documents, :converted_id, :converted_doi

      def fetch
        @documents ||= Nokogiri::XML(URI.open(URL))
          .xpath("/body/query/doi_record/report-paper/report-paper_metadata")
          .map { |doc| parse_docid doc }
      rescue StandardError => e
        warn e.message
        []
      end

      def convert(doc)
        id = @converted_id[doc[:id]] ||= NistPubid::Document.parse(doc[:id])
        return id.to_s(:short) unless doc.key?(:doi)

        doi = @converted_doi[doc[:doi]] ||= NistPubid::Document.parse(doc[:doi])
        # return more complete pubid
        id.weight < doi.weight ? doi.to_s(:short) : id.to_s(:short)
      rescue Errors::ParseError
        @converted_doi[doc[:doi]] ||= NistPubid::Document.parse(doc[:doi]).to_s(:short)
      end

      def parse_docid(doc)
        id = doc.at("publisher_item/item_number", "publisher_item/identifier")
          .text.sub(%r{^/}, "")
        doi = doc.at("doi_data/doi").text.gsub("10.6028/", "")
        case doi
        when "10.6028/NBS.CIRC.12e2revjune" then id.sub!("13e", "12e")
        when "10.6028/NBS.CIRC.36e2" then id.sub!("46e", "36e")
        when "10.6028/NBS.HB.67suppJune1967" then id.sub!("1965", "1967")
        when "10.6028/NBS.HB.105-1r1990" then id.sub!("105-1-1990", "105-1r1990")
        when "10.6028/NIST.HB.150-10-1995" then id.sub!(/150-10$/, "150-10-1995")
        end

        { id: id, doi: doi }
      end

      def comply_with_pubid
        fetch.select do |doc|
          convert(doc) == doc[:id]
        rescue Errors::ParseError
          false
        end
      end

      def different_with_pubid
        fetch.reject do |doc|
          convert(doc) == doc[:id]
        rescue Errors::ParseError
          true
        end
      end

      def parse_fail_with_pubid
        fetch.select do |doc|
          convert(doc) && false
        rescue Errors::ParseError
          true
        end
      end
    end
  end
end
