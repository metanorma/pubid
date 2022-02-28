require "nokogiri"
require "net/http"

module PubidIso
  class Scrapper
    DOMAIN = "https://www.iso.org"

    class << self
      def parse_page(path, lang = nil) # rubocop:disable Metrics/AbcSize, Metrics/MethodLength, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
        doc, url = get_page "#{path.sub '/sites/isoorg', ''}.html"
        edition = doc&.xpath("//strong[contains(text(), 'Edition')]/..")
                    &.children&.last&.text&.match(/\d+/)&.to_s

        { urn: fetch_urn(doc, item_ref(doc), edition, languages(doc, lang)) }
      end

      def get_page(path)
        url = DOMAIN + path
        uri = URI url
        resp = Net::HTTP.get_response(uri) # .encode("UTF-8")
        case resp.code
        when "301"
          path = resp["location"]
          url = DOMAIN + path
          uri = URI url
          resp = Net::HTTP.get_response(uri) # .encode("UTF-8")
        when "404", "302"
          raise RelatonBib::RequestError, "#{url} not found."
        end
        n = 0
        while resp.body !~ /<strong/ && n < 10
          resp = Net::HTTP.get_response(uri) # .encode("UTF-8")
          n += 1
        end
        [Nokogiri::HTML(resp.body), url]
      rescue SocketError, Timeout::Error, Errno::EINVAL, Errno::ECONNRESET,
        EOFError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError,
        Net::ProtocolError, Errno::ETIMEDOUT
        raise RelatonBib::RequestError, "Could not access #{url}"
      end

      def item_ref(doc)
        doc.at("//nav[contains(@class, 'heading-condensed')]/h1")&.text
      end

      def fetch_docid(doc, edition, langs)
        pubid = item_ref doc
        [
          RelatonBib::DocumentIdentifier.new(id: pubid, type: "ISO", primary: true),
          RelatonBib::DocumentIdentifier.new(
            id: fetch_urn(doc, pubid, edition, langs), type: "URN",
            ),
        ]
      end

      # @param doc [Nokogiri:HTML::Document]
      # @param pubid [String]
      # @param edition [String]
      # @param langs [Array<Hash>]
      # @returnt [String]
      def fetch_urn(doc, pubid, edition = nil, langs = []) # rubocop:disable Metrics/AbcSize, Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity, Metrics/MethodLength
        orig = pubid.split.first.downcase.split("/").join "-"
        %r{(?<=)(?<type>DATA|GUIDE|ISP|IWA|PAS|R|TR|TS|TTA)} =~ pubid
        _, part, _year, corr, = ref_components pubid
        urn = "urn:iso:std:#{orig}"
        urn += ":#{type.downcase}" if type
        urn += ":#{fetch_docnumber(doc)}"
        urn += ":-#{part}" if part
        urn += ":stage-#{stage_code(doc)}"
        urn += ":ed-#{edition}" if edition
        if corr
          corrparts = corr.split
          urn += ":#{corrparts[0].downcase}:#{corrparts[-1]}"
        end
        urn += ":#{langs.map { |l| l[:lang] }.join(',')}"
        urn
      end

      def stage_code(doc)
        doc.at("//ul[@class='dropdown-menu']/li[@class='active']"\
               "/a/span[@class='stage-code']").text
      end

      def fetch_docnumber(doc)
        item_ref(doc)&.match(/\d+/)&.to_s
      end

      def ref_components(ref)
        %r{
          ^(?<code>ISO(?:\s|/)[^-/:()]+\d+)
          (?:-(?<part>[\w-]+))?
          (?::(?<year>\d{4}))?
          (?:/(?<corr>\w+(?:\s\w+)?\s\d+)(?:(?<coryear>\d{4}))?)?
        }x =~ ref
        [code&.strip, part, year, corr, coryear]
      end

      def languages(doc, lang)
        lgs = [{ lang: "en" }]
        doc.css("li#lang-switcher ul li a").each do |lang_link|
          lang_path = lang_link.attr("href")
          l = lang_path.match(%r{^/(fr)/})
          lgs << { lang: l[1], path: lang_path } if l && (!lang || l[1] == lang)
        end
        lgs
      end


    end
  end
end
