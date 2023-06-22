module Pubid::Ieee::Renderer
  class Base < Pubid::Core::Renderer::Base
    def render_identifier(params)
      if params[:iso_identifier].to_s != "" && params[:number] != ""
        " (%{publisher}%{stage}%{draft_status}%{type}%{number}%{iteration}%{part}%{subpart}%{month}%{year}%{corrigendum_comment}"\
        "%{corrigendum}%{draft}%{edition})%{alternative}%{supersedes}%{reaffirmed}%{incorporates}%{supplement}"\
        "%{revision}%{iso_amendment}%{amendment}%{includes}%{redline}%{adoption}" % params
      else
        "%{publisher}%{stage}%{draft_status}%{type}%{number}%{iteration}%{part}%{subpart}%{month}%{year}%{corrigendum_comment}"\
        "%{corrigendum}%{draft}%{edition}%{alternative}%{supersedes}%{reaffirmed}%{incorporates}%{supplement}"\
        "%{revision}%{iso_amendment}%{amendment}%{includes}%{redline}%{adoption}" % params
      end
    end

    def render_number(number, _opts, _params)
      " #{number}"
    end

    def render_publisher(publisher, opts, params)
      # don't render publisher if no number assigned
      super if params[:number]
    end

    def render_type(type, opts, params)
      result = type.to_s(params[:publisher] == "IEEE" ? opts[:format] : :alternative)

      " #{result}" unless result.empty?
      #" #{type}"
    end

    def render_part(part, _opts, _params)
      "#{part}"
    end

    def render_month(month, _opts, _params)
      ", #{month}"
    end

    def render_corrigendum_comment(corrigendum_comment, _opts, params)
      "/Cor 1-#{params[:year]}" if params[:year]
    end

    def render_year(year, _opts, params)
      return " #{year}" if params[:month]

      if params[:corrigendum_comment]
        "-#{params[:corrigendum_comment].year}"
      elsif params[:reaffirmed] && params[:reaffirmed].key?(:reaffirmation_of)
        "-#{params[:reaffirmed][:reaffirmation_of].year}"
      else
        "-#{year}"
      end
    end

    def render_includes(includes, _opts, _params)
      if includes.is_a?(Hash) && includes[:supplement]
        return " (Includes Supplement #{includes[:supplement]})"
      end

      " (Includes #{includes})"
    end

    def render_edition(edition, _opts, _params)
      result = ""
      if edition[:version]
        result += edition[:version] == "First" ? " Edition 1.0 " : " Edition #{edition[:version]} "
      end

      if edition[:year]
        result += if edition[:version]
                    "#{edition[:year]}"
                  else
                    " #{edition[:year]} Edition"
                  end
      end

      if edition[:month]
        month = edition[:month]
        month = Date.parse(edition[:month]).month if month.to_i.zero?
        result += "-#{sprintf('%02d', month)}"
      end
      result += "-#{edition[:day]}" if edition[:day]
      result
    end

    def render_alternative(alternative, _opts, _params)
      if alternative.is_a?(Array)
        " (#{alternative.map { |a| Pubid::Ieee::Identifier::Base.new(**Pubid::Ieee::Identifier.convert_parser_parameters(**a)) }.join(', ')})"
      else
        " (#{Pubid::Ieee::Identifier::Base.new(**Pubid::Ieee::Identifier.convert_parser_parameters(**alternative))})"
      end
    end

    def render_draft(draft, _opts, _params)
      draft = Pubid::Ieee::Identifier.merge_parameters(draft) if draft.is_a?(Array)

      result = "/D#{draft[:version].is_a?(Array) ? draft[:version].join('D') : draft[:version]}"
      result += ".#{draft[:revision]}" if draft[:revision]
      result += ", #{draft[:month]}" if draft[:month]
      result += " #{draft[:day]}," if draft[:day]
      result += " #{draft[:year]}" if draft[:year]
      result
    end

    def render_draft_status(draft_status, opts, _params)
      " #{draft_status}" if opts[:format] == :full
    end

    def render_revision(revision, _opts, _params)
      " (Revision of #{revision.join(' and ')})" if revision
    end

    def render_redline(_redline, _opts, _params)
      " - Redline"
    end


    def render_amendment(amendment, _opts, _params)
      return " (Amendment to #{amendment})" unless amendment.is_a?(Array)

      result = " (Amendment to #{amendment.first} as amended by "
      result += if amendment.length > 2
                  "#{amendment[1..-2].map(&:to_s).join(', ')}, and #{amendment[-1]}"
                else
                  amendment.last.to_s
                end

      "#{result})"
    end

    def render_corrigendum(corrigendum, _opts, params)
      # if corrigendum.nil?
      #   (params[:year] && corrigendum_comment && "/Cor 1-#{params[:year]}") || ""
      # else
      if corrigendum[:year]
        "/Cor #{corrigendum[:version]}-#{corrigendum[:year]}"
      else
        "/Cor #{corrigendum[:version]}"
      end
      # end
    end

    def render_supersedes(supersedes, _opts, _params)
      if supersedes.length > 2
        " (Supersedes #{supersedes.join(', ')})"
      else
        " (Supersedes #{supersedes.join(' and ')})"
      end
    end

    def render_reaffirmed(reaffirmed, _opts, params)
      return " (Reaffirmed #{params[:year]})" if reaffirmed.key?(:reaffirmation_of)

      " (Reaffirmed #{reaffirmed[:year]})" if reaffirmed[:year]
    end

    def render_incorporates(incorporates, _opts, _params)
      " (Incorporates #{incorporates.join(', and ')})"
    end

    def render_supplement(supplement, _opts, _params)
      " (Supplement to #{supplement})" if supplement
    end

    def render_adoption_year(adoption_year, _opts, _params)
      adoption_id = dup
      adoption_id.year = adoption_year
      " (Adoption of #{adoption_id.identifier})"
    end

    def render_adoption(adoption, _opts, _params)
      adoption
    end

    def render_iso_amendment(iso_amendment, _opts, _params)
      "/Amd#{iso_amendment[:version]}" +
        (iso_amendment[:year] ? "-#{iso_amendment[:year]}" : "")
    end

    def render_adoption(adoption, opts, _params)
      " (Adoption of #{Pubid::Ieee::Identifier::Base.transform(**adoption)})"
    end
  end
end
