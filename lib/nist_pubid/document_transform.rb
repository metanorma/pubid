module NistPubid
  class DocumentTransform
    def apply(tree, context = nil)
      series = tree[:series].to_s.gsub(".", " ")
      document_parameters = tree.reject do |k, _|
        %i[report_number first_report_number second_report_number series parts].include?(k)
      end
      tree[:parts]&.each { |part| document_parameters.merge!(part) }
      report_number = tree.values_at(:first_report_number,
                                     :second_report_number).compact.join("-").upcase

      # using :report_number when need to keep original words case
      report_number = tree[:report_number] if report_number.empty?

      Document.new(publisher: Publisher.parse(series),
                   serie: Serie.new(serie: series),
                   docnumber: report_number,
                   **document_parameters)
    end
  end
end
