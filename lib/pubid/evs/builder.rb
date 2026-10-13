# frozen_string_literal: true

module Pubid
  module Evs
    # Builds an EVS identifier from the composed parse tree. The structured
    # :adopted subtree (produced by the embedded CEN grammar) goes straight
    # to the CEN/CENELEC builder as data — no string re-serialization
    # anywhere; the ISO/IEC and plain-Estonian shapes carry their captures
    # directly.
    class Builder < Pubid::Builder::Base
      def self.build(parsed_data)
        new.build(parsed_data)
      end

      def build(data)
        data = flatten_array(data) if data.is_a?(Array)

        identifier =
          if data[:adopted]
            Identifiers::NationalAdoption.new(
              base: Pubid::CenCenelec::Builder.build(data[:adopted]),
              **shared(data),
            )
          elsif data[:intl]
            intl = data[:intl]
            Identifiers::InternationalAdoption.new(
              intl_org: extract(intl[:intl_org]),
              number: extract(intl[:number]),
              part: extract(intl[:part]),
              year: extract(intl[:year]),
              **shared(data),
            )
          else
            plain = data[:plain]
            Identifiers::EstonianStandard.new(
              number: extract(plain[:number]),
              year: extract(plain[:year]),
              evs_type: extract(plain[:evs_type]),
              **shared(data),
            )
          end

        attach_supplements(identifier, data)
      end

      private

      def shared(data)
        {
          separator: extract(data[:evs_separator]) || "-",
          draft_prefix: data[:draft_prefix] ? true : false,
          language: extract(data[:language]),
        }
      end

      def attach_supplements(identifier, data)
        if data[:na]
          identifier.na_separator = supplement_separator(data[:na])
          identifier.na_year = extract(data[:na][:na_year])
        end
        if data[:evs_amd]
          identifier.amd_separator = supplement_separator(data[:evs_amd])
          identifier.amd_kind = extract(data[:evs_amd][:amd_kind])
          identifier.amd_number = extract(data[:evs_amd][:amd_number])
          identifier.amd_year = extract(data[:evs_amd][:amd_year])
        end
        if data[:evs_cor]
          identifier.cor_separator = supplement_separator(data[:evs_cor])
          identifier.cor_kind = extract(data[:evs_cor][:cor_kind])
          identifier.cor_number = extract(data[:evs_cor][:cor_number])
          identifier.cor_year = extract(data[:evs_cor][:cor_year])
        end
        identifier
      end

      def supplement_separator(supp)
        %i[supp_plus supp_slash supp_space]
          .map { |k| extract(supp[k]) }.compact.first
      end

      def extract(value)
        value.is_a?(Hash) ? value[:value] : value
      end
    end
  end
end

Pubid::Evs::Builder.prepend(Pubid::Builder::AllPartsWrap)
