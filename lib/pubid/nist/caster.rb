# frozen_string_literal: true

module Pubid
  module Nist
    # Caster class for NIST type coercion
    # Single Responsibility: Convert parsed values to domain component objects
    #
    # Extracted from Builder to isolate the 1200+ line type coercion switch
    # from orchestration logic. Caster is stateless — each call to #cast
    # receives all the context it needs via parameters.
    class Caster
      # Translation normalization map (V1 compatibility)
      TRANSLATION_MAP = {
        "es" => "spa",
        "sp" => "spa",
        "pt" => "por",
        "id" => "ind",
        "chi" => "zho",
        "viet" => "vie",
        "port" => "por",
        "esp" => "spa",
      }.freeze

      # Cast parsed value to appropriate component type
      # ALL conversions happen in this single method
      # @param type [Symbol] the parameter type
      # @param value [Object] the parsed value
      # @param parsed_hash [Hash] the full parsed hash for context
      # @return [Object, Hash, nil] the cast component(s)
      def cast(type, value, parsed_hash = {})
        case type
        when :publisher
          return nil if value.nil? || value.to_s.strip.empty?

          # publisher is a plain string attribute (see Identifier).
          value.to_s

        when :dated_date
          # Date-style identifier (DatedDocument): carry the YYYY-MM-DD parts
          # as string attributes.
          return nil unless value.is_a?(Hash)

          { date_year: value[:date_year]&.to_s, date_month: value[:date_month]&.to_s,
            date_day: value[:date_day]&.to_s }

        when :dated_seq
          return nil if value.to_s.strip.empty?

          { dated_seq: value.to_s }

        when :year
          # Bare 4-digit year (e.g. from "NIST Research Library (2022)").
          # The Identifier#year attribute is typed as :integer.
          value&.to_s&.to_i

        when :series
          return nil if value.nil? || value.to_s.strip.empty?

          str_value = value.to_s
          publisher_extracted = nil

          # Compound series carry the publisher inside the series token (e.g.
          # "NBS CIRC", "NIST DCI") because the bare series code isn't recognized
          # by the grammar on its own. Split the leading publisher out so
          # `series` holds just the code and `publisher` is populated — matching
          # how standalone series (NIST SP, NBS CS) already parse, and avoiding a
          # nil publisher (which renders fine via the series string but would
          # otherwise force a misleading publisher_was_parsed: false). Routing
          # already ran on the raw compound series, so stripping here can't
          # change the identifier class.
          if (m = str_value.match(/\A(NBS|NIST) (.+)\z/))
            publisher_extracted = m[1]
            str_value = m[2]
          end

          # Return composite hash with both publisher and series if extracted
          if publisher_extracted
            {
              publisher: publisher_extracted,
              series: Components::Code.new(value: str_value),
            }
          else
            Components::Code.new(value: str_value)
          end

        when :volume_number
          # Volume from v#n# pattern - return Volume component
          return nil if value.nil? || value.to_s.strip.empty?

          { volume: Components::Volume.new(value: value.to_s) }

        when :issue_number
          # Issue number from v#n# pattern - return Part component
          return nil if value.nil? || value.to_s.strip.empty?

          { part: Components::Part.new(type: "n", value: value.to_s) }

        when :part_number
          # Part number from GCR pattern (e.g., 85-3273-37)
          # Return raw value for inclusion in compound number
          return nil if value.nil? || value.to_s.strip.empty?

          value # Return raw value to be tracked in builder

        when :letter_number
          # Letter suffix from a dashed pattern (e.g., 800-56A → {:letter_base=>"56", :letter_suffix=>"A"}).
          # Series policy decides whether the suffix becomes a Part component
          # (default) or stays in the number (MONO/NCSTAR/IR-with-R-or-Ur).
          return nil if value.nil? || !value.is_a?(Hash)

          Series.for(parsed_hash).cast_letter_number(value, parsed_hash)

        when :fips_part
          # Part number from FIPS date pattern (e.g., 11-1-Sep30/1977)
          # Return Part component with pt type
          return nil if value.nil? || value.to_s.strip.empty?

          { part: Components::Part.new(type: "pt", value: value.to_s) }

        when :owmwp_date_number
          # OWMWP date-based number format (MM-DD-YYYY)
          # Parser returns: {:owmwp_month=>"06", :owmwp_day=>"13", :owmwp_year=>"2018"}
          # Convert to number + edition: "06-13" + edition "e2018"
          return nil if value.nil?

          number_part = "#{value[:owmwp_month]}-#{value[:owmwp_day]}"
          edition_part = Components::Edition.new(type: "e",
                                                 id: value[:owmwp_year])
          { first_number: Components::Code.new(value: number_part), edition: edition_part }

        when :first_number, :second_number
          return nil if value.nil? || value.to_s.strip.empty?

          # NEW: Handle OWMWP date-based number (nested hash structure)
          # Parser returns: {:owmwp_date_number=>{:owmwp_month=>"06", :owmwp_day=>"13", :owmwp_year=>"2018"}}
          # Convert to number + edition: "06-13" + edition "e2018"
          if value.is_a?(Hash) && value[:owmwp_date_number]
            owmwp_hash = value[:owmwp_date_number]
            number_part = "#{owmwp_hash[:owmwp_month]}-#{owmwp_hash[:owmwp_day]}"
            edition_part = Components::Edition.new(type: "e",
                                                   id: owmwp_hash[:owmwp_year])
            return { type => Components::Code.new(value: number_part), edition: edition_part }
          end

          # NEW: Handle second_number with edition (hash with :number_only and :edition_id)
          # This handles "126r2013" pattern where parser returns {:number_only=>"126", :edition_id=>"2013"}
          # CRITICAL: Wrap in a structure that builder loop can recognize
          # The builder loop expects keys like :second_number to be present in the hash
          if type == :second_number && value.is_a?(Hash) && value[:number_only] && value[:edition_id]
            # Return wrapped hash so builder loop finds :second_number key
            return { second_number: value }
          end

          # NEW: Handle second_number with revision_letter (hash with :revision_letter containing :number_only and :letter)
          # This handles "27ra" pattern where parser returns {revision_letter: {number_only: "27", letter: "a"}}
          # Should be combined to "27rA" format
          if type == :second_number && value.is_a?(Hash) && value[:revision_letter]
            revision_data = value[:revision_letter]
            number_only = revision_data[:number_only].to_s
            letter = revision_data[:letter].to_s.upcase
            # Return as second_number with combined format "27rA"
            return { second_number: Components::Code.new(value: "#{number_only}r#{letter}") }
          end

          # Handle v#n# pattern (CSM series) - comes as hash from parser
          # Return Volume and Part components separately
          if value.is_a?(Hash) && value[:volume_number] && value[:issue_number]
            volume_num = value[:volume_number].to_s
            issue_num = value[:issue_number].to_s
            return {
              volume: Components::Volume.new(value: volume_num),
              part: Components::Part.new(type: "n", value: issue_num),
            }
          end

          str_value = value.to_s

          # Handle special patterns embedded in first_number
          if type == :first_number

            # NEW: Handle first_number hash with number_with_rev_year (e.g., "1013rv1953")
            # Parser returns: {:number_with_rev_year=>{:number=>"1013", :revision_year=>"1953"}}
            if value.is_a?(Hash) && value[:number_with_rev_year]
              number_part = value[:number_with_rev_year][:number].to_s
              revision_year = value[:number_with_rev_year][:revision_year].to_s
              return {
                first_number: Components::Code.new(value: number_part),
                edition: Components::Edition.new(type: "rv", id: revision_year),
              }
            end

            # Handle first_number with letter suffix and revision (e.g., "8278Ar1", "256Ar1930")
            # Parser returns: {:number_with_letter_revision=>{:number=>"8278", :letter_suffix=>"A", :revision_id=>"1"}}
            # Splits into number + Part(letter) + Edition(r, id) to mirror how :letter_number
            # (dash-separated "56Ar2") is decomposed for SpecialPublication and similar series.
            if value.is_a?(Hash) && value[:number_with_letter_revision]
              data = value[:number_with_letter_revision]
              return {
                first_number: Components::Code.new(value: data[:number].to_s),
                part: Components::Part.new(type: "",
                                           value: data[:letter_suffix].to_s.upcase),
                edition: Components::Edition.new(type: "r",
                                                 id: data[:revision_id].to_s),
              }
            end

            # NEW: Handle first_number hash with language_code (e.g., "1262es")
            # Parser returns: {:number=>"1262", :language_code=>"es"}
            if value.is_a?(Hash) && value[:number] && value[:language_code]
              number_part = value[:number].to_s
              language_code = value[:language_code].to_s.strip.downcase
              # Apply normalization map (es -> spa, pt -> por, etc.)
              normalized_code = TRANSLATION_MAP[language_code] || language_code
              return {
                first_number: Components::Code.new(value: number_part),
                translation_component: Components::Translation.new(code: normalized_code),
              }
            end

            # NEW: Handle first_number hash with number, part_number, and edition_year (MR format)
            # Parser returns: {:number=>"28", :part_number=>"1", :edition_year=>"1969"}
            # For "NBS.HB.28pt1e1969" MR format input
            if value.is_a?(Hash) && value[:number] && value[:part_number] && value[:edition_year]
              number_part = value[:number].to_s
              part_number = value[:part_number].to_s
              edition_year = value[:edition_year].to_s
              return {
                first_number: Components::Code.new(value: number_part),
                part: Components::Part.new(type: "pt", value: part_number),
                edition: Components::Edition.new(type: "e", id: edition_year),
              }
            end

            # NEW: Check for edition_year_separate in parsed_hash context
            # This handles "11e2-1915" where first_number="11e2" and edition_year_separate="1915"
            if parsed_hash[:edition_year_separate] && str_value =~ /^(\d+)e(\d+)$/
              number_part = $1
              edition_id = $2
              year_part = parsed_hash[:edition_year_separate].to_s
              return {
                first_number: Components::Code.new(value: number_part),
                edition: Components::Edition.new(type: "e", id: edition_id,
                                                 additional_text: year_part),
              }
            end

            # NEW: Check for number_with_volume in value hash (for first_number)
            # This handles "539v10" where parser captures :number and :volume_suffix separately
            # Parse tree: value = {:number_with_volume => {:number => "539", :volume_suffix => "10"}}
            if value.is_a?(Hash) && value[:number_with_volume] && value[:number_with_volume][:volume_suffix]
              number_part = value[:number_with_volume][:number].to_s
              volume_value = value[:number_with_volume][:volume_suffix].to_s
              return {
                first_number: Components::Code.new(value: number_part),
                volume: Components::Volume.new(value: volume_value),
              }
            end

            # NEW: Check for historical_month and historical_year in parsed_hash context
            # This handles "-April1909" where it's captured as separate month/year
            if parsed_hash[:historical_month] && parsed_hash[:historical_year]
              month_part = parsed_hash[:historical_month].to_s
              year_part = parsed_hash[:historical_year].to_s
              # Check if str_value is just a number (the part before dash)
              if /^\d+$/.match?(str_value)
                return {
                  first_number: Components::Code.new(value: str_value),
                  edition: Components::Edition.new(type: "-",
                                                   additional_text: "#{month_part}#{year_part}"),
                }
              else
                # No number, just historical edition
                return {
                  edition: Components::Edition.new(type: "-",
                                                   additional_text: "#{month_part}#{year_part}"),
                }
              end
            end

            # Pattern "9350sup"/"5893supp" - number with bare supplement marker
            # (no trailing payload). Accept both single-p "sup" and double-p
            # "supp" so the marker is isolated as supplement="" and rendered as
            # canonical single-p "sup", instead of staying baked into the number
            # as an opaque suffix. E.g. "NBS RPT 5893supp", "NBS MONO 32supp".
            if str_value =~ /^(\d+)supp?$/
              return {
                first_number: Components::Code.new(value: $1),
                supplement: "",
              }
            end

            # NEW: Check for supplement_year in parsed_hash context
            # This handles "25supp-1924" where first_number="25supp" and supplement_year="1924"
            if parsed_hash[:supplement_year] && str_value =~ /^(\d+)supp?$/
              number_part = $1
              year_part = parsed_hash[:supplement_year].to_s
              return {
                first_number: Components::Code.new(value: number_part),
                supplement: year_part,
              }
            end

            # Pattern: "154supprev" - supplement with revision
            if str_value =~ /^(\d+)supprev$/
              return {
                first_number: Components::Code.new(value: $1),
                supplement: "",
                supplement_has_revision: true,
              }
            # NEW: Pattern "11e2-1915" - edition with separate year (inline match)
            # Creates: number="11", Edition(type: "e", id: "2", additional_text: "1915")
            # Renders: "NBS CIRC 11e2.1915"
            elsif str_value =~ /^(\d+)e(\d+)-(\d{4})$/
              number_part = $1
              edition_id = $2
              year_part = $3
              return {
                first_number: Components::Code.new(value: number_part),
                edition: Components::Edition.new(type: "e", id: edition_id,
                                                 additional_text: year_part),
              }
            # NEW: Pattern "-April1909" - historical edition with month+year (inline match)
            # Creates: Edition(type: "-", additional_text: "April1909")
            # Renders: "NBS CIRC -April1909"
            elsif str_value =~ /^-([A-Za-z]{3,9})(\d{4})$/
              month_part = $1
              year_part = $2
              return {
                edition: Components::Edition.new(type: "-",
                                                 additional_text: "#{month_part}#{year_part}"),
              }
            # NEW: CS Emergency pattern "e104" or "e104-43" -> extract number
            # This must come BEFORE bare edition check to avoid conflict
            # CS emergency always has 3+ digit number (e104, not e2)
            # NOTE: If second_number exists (e104-43 pattern), defer to compound number logic
            elsif /^e(\d{3,})$/.match?(str_value) && !parsed_hash[:second_number]
              # Extract emergency number: e104 -> 104 (only when no second_number)
              emergency_num = str_value.sub(/^e/, "")
              return {
                first_number: Components::Code.new(value: emergency_num),
              }
            # If e104-43 pattern (with second_number), keep e prefix for compound number logic
            elsif /^e(\d{3,})$/.match?(str_value) && parsed_hash[:second_number]
              # Keep e104 as-is, let compound number logic handle it
              return {
                first_number: Components::Code.new(value: str_value),
              }
            # NEW: Bare edition pattern like "100e1" (CS series without year)
            # ONLY when NO second_number present (to avoid conflict with "123e2-50")
            # Creates: number="100", Edition(type: "e", id: "1")
            # Renders: "NBS CS 100e1"
            # CRITICAL: Skip if edition_dash_year is present - let that handler create Edition with additional_text
            elsif str_value =~ /^(\d+)e(\d+)$/ && !parsed_hash[:second_number] && !parsed_hash[:edition_dash_year]
              number_part = $1
              edition_id = $2

              return {
                first_number: Components::Code.new(value: number_part),
                edition: Components::Edition.new(type: "e", id: edition_id),
              }
            # NEW: Bare edition pattern "e2" - just edition without number prefix
            # Creates: Edition(type: "e", id: "2")
            # Renders: "NBS CIRC e2"
            # Only matches single or double digit (e1, e2, not e104 which is emergency)
            elsif str_value =~ /^e(\d{1,2})$/
              edition_id = $1
              return {
                edition: Components::Edition.new(type: "e", id: edition_id),
              }
            # Pattern: "13e2rev1908" - edition with revision year-only (NO month)
            # Creates: Edition(type: "e", id: "2", additional_text: "1908")
            # Renders: "e2.1908" (DOT separator)
            elsif str_value =~ /^(\d+)e(\d+)rev(\d{4})$/
              # CRITICAL: Capture BEFORE any regex method calls!
              number_part = $1
              edition_id_part = $2
              year_part = $3
              return {
                first_number: Components::Code.new(value: number_part),
                edition: Components::Edition.new(type: "e",
                                                 id: edition_id_part, additional_text: year_part),
              }
            # Pattern: "13e2revJune1908" - edition with revision month+year
            # Creates: Edition(type: "e", id: "2", additional_text: "June1908")
            # Renders: "e2.June1908" (DOT separator)
            elsif str_value =~ /^(\d+)e(\d+)(rev.+)$/
              # CRITICAL: Capture $1, $2, $3 BEFORE calling .sub() which resets them!
              number_part = $1
              edition_id_part = $2
              rev_part = $3
              # Strip "rev" prefix from additional_text - store only "June1908" or "1908"
              additional_text = rev_part.sub(/^rev/, "")
              return {
                first_number: Components::Code.new(value: number_part),
                edition: Components::Edition.new(type: "e",
                                                 id: edition_id_part, additional_text: additional_text),
              }
            # NEW: Pattern "24suppJan1924" - supplement with month and year in first_number
            # Creates: number="24", supplement="Jan1924"
            elsif str_value =~ /^(\d+)supp([A-Za-z]{3,9})(\d{4})$/
              number_part = $1
              month_part = $2
              year_part = $3
              return {
                first_number: Components::Code.new(value: number_part),
                supplement: "#{month_part}#{year_part}",
              }
            # NEW: Pattern "25supp1924" - supplement with year (no dash, no month)
            # Creates: number="25", supplement="1924"
            # Renders: "NBS SP 25supp1924"
            elsif str_value =~ /^(\d+)supp(\d{4})$/
              number_part = $1
              year_part = $2
              return {
                first_number: Components::Code.new(value: number_part),
                supplement: year_part,
              }
            # NEW: Pattern "25supp-1924" - supplement with dash-year (inline match)
            # Creates: number="25", supplement="1924"
            # Renders: "NBS CIRC 25supp-1924"
            elsif str_value =~ /^(\d+)supp-(\d{4})$/
              number_part = $1
              year_part = $2
              return {
                first_number: Components::Code.new(value: number_part),
                supplement: year_part,
              }
            # NEW: Pattern "101e2supp" - edition + supplement
            # Creates: number="101", Edition(type: "e", id: "2"), supplement=""
            # Renders: "NBS CIRC 101e2supp"
            elsif str_value =~ /^(\d+)e(\d+)supp$/
              number_part = $1
              edition_id = $2
              return {
                first_number: Components::Code.new(value: number_part),
                edition: Components::Edition.new(type: "e", id: edition_id),
                supplement: "",
              }
            end
          elsif type == :second_number && value.is_a?(Hash) && value[:first_number]
            # Handle second_number as a hash with first_number context
            # e.g., for pattern 800-57pt1r4
            number_part = value[:first_number].to_s
            part_value = value[:part_value]&.to_s
            revision_value = value[:revision_value]&.to_s
            return {
              first_number: Components::Code.new(value: number_part),
              part: Components::Part.new(value: part_value),
              edition: Components::Edition.new(type: "r", id: revision_value),
            }
          end

          # Extract revision suffix from number (e.g., "53r5" -> "53" + Edition(r, 5))
          # ENHANCED: Also extract revision with slash-year (e.g., "53r5/1917" -> "53" + Edition)
          # ENHANCED: Also extract revision with 4-digit year (e.g., "1019r1963" -> "1019" + Edition)
          # ENHANCED: Also extract revision with month+year (e.g., "4743rJun1992" -> "4743" + Edition)

          # NEW: Extract part suffix from number (e.g., "800-57pt1" -> "800-57" + Part(1))
          # This handles SP series part notation
          # IMPORTANT: Handle combined part+revision first (e.g., "800-57pt1r4")
          if str_value =~ /^(.+?)pt(\d+)r(\d+[a-z]?)$/
            number_part = $1
            part_value = $2
            revision_value = $3
            return {
              type => Components::Code.new(value: number_part),
              part: Components::Part.new(type: "pt", value: part_value),
              edition: Components::Edition.new(type: "r", id: revision_value),
            }
          elsif str_value =~ /^(.+?)pt(\d+)$/
            number_part = $1
            part_value = $2
            return {
              type => Components::Code.new(value: number_part),
              part: Components::Part.new(type: "pt", value: part_value),
            }
          end

          # NEW: Extract volume suffix from number (e.g., "539v10" -> "539" + volume="10")
          # This handles CIRC volume notation
          if str_value =~ /^(\d+)v(\d+)$/
            number_part = $1
            volume_part = $2
            return {
              type => Components::Code.new(value: number_part),
              volume: volume_part,
            }
          end

          # REVISION PATTERNS - These must come BEFORE letter suffix to avoid conflicts
          case str_value
          when /^(.+?)(r\d+\/\d{4})$/i
            # Pattern: r6/1925 (revision with slash-year)
            number_part = $1
            revision_with_year = $2 # e.g., "r6/1925"
            # Extract revision and year
            if revision_with_year =~ /^r(\d+)\/(\d{4})$/
              revision_id = $1
              year_part = $2
              return {
                type => Components::Code.new(value: number_part),
                edition: Components::Edition.new(type: "r", id: revision_id,
                                                 additional_text: year_part),
              }
            end
          when /^(.*\d)(r\d{4})$/i
            # Pattern: r1963 (revision as 4-digit year)
            number_part = $1
            year_value = $2.sub(/^r/, "") # Strip 'r' prefix
            return {
              type => Components::Code.new(value: number_part),
              edition: Components::Edition.new(type: "r", id: year_value),
            }
          when /^(.+?)(r[A-Za-z]{3,9}\d{4})$/i
            # Pattern: rJun1992 (revision with month and year)
            number_part = $1
            revision_with_date = $2 # e.g., "rJun1992"
            # Extract month and year
            if revision_with_date =~ /^r([A-Za-z]{3,9})(\d{4})$/
              month_part = $1
              year_part = $2
              return {
                type => Components::Code.new(value: number_part),
                edition: Components::Edition.new(type: "r",
                                                 id: "#{month_part}#{year_part}"),
              }
            end
          when /^(.*\d)(r\d+[a-z]?)$/i
            # Pattern: r5, r1a (simple revision)
            number_part = $1
            revision_value = $2.sub(/^r/, "") # Strip 'r' prefix
            return {
              type => Components::Code.new(value: number_part),
              edition: Components::Edition.new(type: "r", id: revision_value),
            }
          when /^(.+?)(?<![a-zA-Z])(r)$/i
            # Pattern: bare r with no digits (e.g., "800-90r")
            # Negative lookbehind ensures r is NOT preceded by a letter (avoids matching Ur, Ua, etc.)
            number_part = $1
            return {
              type => Components::Code.new(value: number_part),
              edition: Components::Edition.new(type: "r", id: "1"),
            }
          end

          # NEW: Extract UPPERCASE letter suffix as Part component (e.g., "800-56A" -> "800-56" + Part)
          # IMPORTANT: These patterns come AFTER revision patterns to avoid conflicts
          # Letter suffixes are UPPERCASE letters A-Z only (no lowercase to avoid revision markers)

          # Pattern: UPPERCASE letter + revision (e.g., "800-56Ar2" -> number + Part("", "A") + Edition(r, 2))
          # NO /i flag - only match uppercase letters!
          if str_value =~ /^(.+?)([A-Z])(r\d+[a-z]?)$/
            number_part = $1
            letter_part = $2
            revision_part = $3.sub(/^r/, "")
            return {
              type => Components::Code.new(value: number_part),
              part: Components::Part.new(type: "", value: letter_part),
              edition: Components::Edition.new(type: "r", id: revision_part),
            }
          # Pattern: bare UPPERCASE letter suffix (e.g., "800-56A" -> number + Part("", "A"))
          # Only matches uppercase letters - won't match revision markers.
          # Series policy decides whether the letter stays in the number
          # (MR format, RPT/FIPS/IR/CRPL/LC/MONO/MP) or becomes a Part.
          elsif str_value =~ /^(.+?)([A-Z])$/
            number_part = $1
            letter_part = $2

            if Series.for(parsed_hash).preserve_letter_suffix?(parsed_hash)
              return { type => Components::Code.new(value: str_value) }
            else
              return {
                type => Components::Code.new(value: number_part),
                part: Components::Part.new(type: "", value: letter_part),
              }
            end
          end

          Components::Code.new(value: str_value)

        when :crpl_range
          return nil if value.nil? || value.to_s.strip.empty?

          # For CRPL range patterns like "2_3-1" or "2_3-1A" (with supplement)
          # Format: X_Y-Z where X,Y,Z are digits, optional trailing letter is supplement
          # This should split into:
          # - X -> second_number (to combine with first_number as "1-X")
          # - Y-Z -> Part component (with type "pt" for CRPL)
          # - trailing letter (if present) -> Supplement
          str_value = value.to_s

          # Check for supplement letter suffix (e.g., "2_3-1A" -> supplement="A")
          if str_value =~ /^(\d+)_(\d+-\d+)([A-Z])$/
            second_num_part = $1 # "2"
            part_value = $2 # "3-1"
            supplement_letter = $3 # "A"

            # Return second_number, Part, and Supplement
            {
              second_number: Components::Code.new(value: second_num_part),
              part: Components::Part.new(type: "pt", value: part_value),
              supplement: supplement_letter,
            }
          elsif str_value =~ /^(\d+)_(\d+-\d+)$/
            # No supplement letter
            second_num_part = $1 # "2"
            part_value = $2 # "3-1"

            # Return second_number and Part
            {
              second_number: Components::Code.new(value: second_num_part),
              part: Components::Part.new(type: "pt", value: part_value),
            }
          else
            # Fallback: treat entire value as second_number (shouldn't happen with valid CRPL patterns)
            Components::Code.new(value: str_value)
          end

        # ========== V2 COMPONENT CASTING ==========

        when :stage
          # Stage from nested hash with id and type
          return nil unless value.is_a?(Hash)

          stage_id = value[:stage_id]&.to_s&.downcase
          stage_type = value[:stage_type]&.to_s&.downcase
          return nil if stage_id.nil? || stage_type.nil? || stage_id.empty? || stage_type.empty?

          # Return as hash to set the stage attribute
          { stage: Components::Stage.new(id: stage_id, type: stage_type) }

        when :stage_id, :stage_type
          # These are captured by :stage, so skip individual processing
          nil

        when :parsed_format
          # Format detection result from parser. :short is the render default
          # (a nil parsed_format renders short — see Identifier#to_s), so
          # store only non-default formats (e.g. "mr"); "short" stays unset and
          # is omitted from to_hash. detect_format only emits :mr or :short.
          v = value&.to_s
          v unless v == "short"

        when :translation
          # V1 TRANSLATION NORMALIZATION
          return nil if value.nil? || value.to_s.strip.empty?

          code = value.to_s.strip.downcase
          # Apply normalization map (es -> spa, pt -> por, etc.)
          normalized_code = TRANSLATION_MAP[code] || code

          # Return as hash to set translation_component attribute
          { translation_component: Components::Translation.new(code: normalized_code) }

        when :version
          # Version component with dotted notation
          return nil if value.nil? || value.to_s.strip.empty?

          # Return as hash to set version_component attribute
          { version_component: Components::Version.new(value: value.to_s) }

        when :update
          # Update component with number, year, and optional month
          if value.is_a?(Hash)
            # Convert Parslet slice to regular Hash for reliable key access
            value_hash = value.to_h

            number = value_hash[:update_number]&.to_s # Don't default to "1"
            year = value_hash[:update_year]&.to_s     # String not integer
            month = value_hash[:update_month]&.to_s   # String not integer

            # Determine prefix from update_prefix key (captured by parser)
            # If not present, default to "slash" (/Upd format)
            prefix_str = value_hash[:update_prefix]&.to_s
            prefix_value = if prefix_str&.include?("-") || prefix_str == "-upd"
                             "dash"
                           else
                             "slash"
                           end

            # Create update with at least number
            update_obj = Components::Update.new(number: number, year: year,
                                                month: month, prefix: prefix_value)
            {
              update: update_obj, # Main attribute for tests
              update_component: update_obj, # V2 component
            }
          elsif value.to_s.strip.empty?
            # Empty update string means "-upd" or "/upd" with no details
            # Create Update with default number="1" (no year/month)
            # Check update_prefix key to determine correct prefix format
            prefix_str = parsed_hash[:update_prefix]&.to_s
            prefix_value = if prefix_str&.include?("-") || prefix_str == "-upd"
                             "dash"
                           else
                             "slash"
                           end
            update_obj = Components::Update.new(number: "1", year: nil,
                                                month: nil, prefix: prefix_value)
            {
              update: update_obj,
              update_component: update_obj,
            }
          else
            # Simple string value - shouldn't reach here
            { update: value.to_s.strip } unless value.to_s.strip.empty?
          end

        when :update_prefix, :update_number, :update_year, :update_month
          # Captured as part of :update processing
          nil

        # ========== END V2 COMPONENTS ==========

        when :volume, :section, :appendix, :translation,
             :errata, :index, :insert, :version
          return nil if value.nil?
          return nil if value.is_a?(Array) && value.empty?

          str_value = value.to_s.strip
          return nil if str_value.empty?

          # For volume, create Volume component from string value
          # This handles patterns like "v1" that come from parser as simple strings
          if type == :volume
            { volume: Components::Volume.new(value: str_value) }
          else
            str_value
          end

        when :revision
          # Revision MUST be Edition component with type "r"
          return nil if value.nil? || value.to_s.strip.empty?

          # Handle new structure with :revision_prefix and :revision_id (format preservation)
          if value.is_a?(Hash) && value[:revision_prefix] && value[:revision_id]
            prefix = value[:revision_prefix].to_s
            id = value[:revision_id].to_s.strip

            # Normalize bare "r" -> "r1"
            revision_id = if id.empty? || id == "r" || id == "R"
                            "1"
                          # Handle "r4", "R5", "4" etc. (but prefix already has the r/rev/etc.)
                          elsif id =~ /^(\d+[a-z]?)$/
                            $1
                          else
                            id
                          end

            # Return Edition component with original_prefix for format preservation
            {
              edition: Components::Edition.new(type: "r", id: revision_id,
                                               original_prefix: prefix),
            }
          else
            # Legacy handling: revision as simple string value
            str_value = value.to_s.strip

            # Handle bare "r" -> normalize to "r1"
            revision_id = if str_value.empty? || str_value == "r" || str_value == "R"
                            "1"
                          # Handle "r4", "R5", "4" etc.
                          elsif str_value =~ /^[rR]?(\d+[a-z]?)$/
                            $1
                          else
                            str_value
                          end

            # Return Edition component (no original_prefix available)
            {
              edition: Components::Edition.new(type: "r", id: revision_id),
            }
          end

        when :revision_year, :revision_month
          # When revision_year comes from parser as separate element (e.g., "1019 r1963")
          # Create Edition component
          if type == :revision_year
            year_value = value.to_s.strip
            # Check if this should be an Edition component or legacy revision_year
            # If revision_month is also present, use legacy attributes for "revJune1908" pattern
            if parsed_hash[:revision_month]
              # Legacy: revision with month - keep as revision_year/revision_month
              year_value
            else
              # V2: revision with year only - create Edition component
              {
                edition: Components::Edition.new(type: "r", id: year_value),
              }
            end
          else
            # revision_month - preserve as string for legacy rendering
            return nil if value.nil? || value.to_s.strip.empty?

            value.to_s.strip
          end

        when :edition_year_separate
          # NEW: Edition year from "e2-1915" pattern (captured separately by parser)
          # This comes with first_number like "11e2" and separate year "1915"
          # Already handled in first_number regex matching above, but if it reaches here
          # as a separate capture, we need to process it
          return nil if value.nil? || value.to_s.strip.empty?

          value.to_s # Return as string for potential use

        when :historical_month
          # NEW: Historical month from "-April1909" pattern
          # Handled in first_number pattern matching, but return as string if separate
          return nil if value.nil? || value.to_s.strip.empty?

          value.to_s

        when :historical_year
          # NEW: Historical year from "-April1909" pattern
          # Handled in first_number pattern matching, but return as string if separate
          return nil if value.nil? || value.to_s.strip.empty?

          value.to_s

        when :supplement_year
          # NEW: Supplement year from "supp-1924" pattern (captured separately by parser)
          # This comes with first_number like "25supp" and separate year "1924"
          # Already handled in first_number regex matching above, but if it reaches here
          # as a separate capture, return as supplement value
          return nil if value.nil? || value.to_s.strip.empty?

          { supplement: value.to_s } # Return as supplement attribute

        when :supplement
          handle_supplement_cast(value)

        when :supplement_date_range
          return nil unless value.is_a?(Hash)

          month_start = value[:supp_month_start]&.to_s
          year_start = value[:supp_year_start]&.to_s
          month_end = value[:supp_month_end]&.to_s
          year_end = value[:supp_year_end]&.to_s

          {
            supplement_date_range_start: (month_start && year_start ? "#{month_start}#{year_start}" : nil),
            supplement_date_range_end: (month_end && year_end ? "#{month_end}#{year_end}" : nil),
          }

        when :supplement_date
          return nil unless value.is_a?(Hash)

          month = value[:supp_month]&.to_s
          year = value[:supp_year]&.to_s

          month && year ? "#{month}#{year}" : nil

        when :supplement_slash_year
          return nil unless value.is_a?(Hash)

          number = value[:supp_number]&.to_s
          year = value[:supp_year]&.to_s

          number && year ? "#{number}/#{year}" : nil

        when :supplement_with_rev
          { supplement: "", supplement_has_revision: true }

        when :supp_year
          # Parser extracts supplement year from patterns like "187supp1924"
          # This should set the supplement attribute with the year value
          { supplement: value.to_s }

        # ========== V2 EDITION COMPONENT ==========

        when :edition_e_date
          # Edition with "e" prefix + 6-digit date (YYYYMM): e199206, e202103
          # Used for IR revision+month patterns after preprocessing: "4743rJun1992" -> "4743e199206"
          return nil unless value.is_a?(Hash) && value[:edition_date]

          edition_date = value[:edition_date].to_s
          # Parse 6-digit date as YYYYMM
          # Store as id directly - renders as "e199206"
          {
            edition: Components::Edition.new(type: "e", id: edition_date),
          }

        when :edition_e
          # Edition with "e" prefix: e2, e2021
          return nil unless value.is_a?(Hash) && value[:edition_id]

          edition_id = value[:edition_id].to_s

          {
            edition: Components::Edition.new(type: "e", id: edition_id),
          }

        when :edition_r
          # Revision with "r" prefix: r5, r2021
          return nil unless value.is_a?(Hash) && value[:edition_id]

          edition_id = value[:edition_id].to_s

          {
            edition: Components::Edition.new(type: "r", id: edition_id),
          }

        when :edition_r_no_space
          # Revision with "r" prefix (no space pattern): r2, r5
          # Used for patterns like "800-56Ar2" where edition is "r2"
          return nil unless value.is_a?(Hash) && value[:edition_id]

          edition_id = value[:edition_id].to_s

          {
            edition: Components::Edition.new(type: "r", id: edition_id),
          }

        when :edition_rev
          # Revision with "rev" prefix (verbose): rev2013, rev 2013
          return nil unless value.is_a?(Hash) && value[:edition_id]

          edition_id = value[:edition_id].to_s

          {
            edition: Components::Edition.new(type: "r", id: edition_id),
          }

        when :edition_r_letter
          # Revision with "r" prefix and letter suffix: r1a, r2b (for SP patterns like 800-22r1a)
          return nil unless value.is_a?(Hash) && value[:edition_id] && value[:edition_letter]

          edition_id = value[:edition_id].to_s
          edition_letter = value[:edition_letter].to_s.downcase

          {
            edition: Components::Edition.new(type: "r", id: edition_id,
                                             additional_text: edition_letter),
          }

        when :edition_r_letter_only
          # Revision with "r" prefix and only letter (no digit): ra, rb (for SP patterns like 800-27ra)
          return nil unless value.is_a?(Hash) && value[:edition_letter]

          edition_letter = value[:edition_letter].to_s.downcase

          {
            edition: Components::Edition.new(type: "r", id: edition_letter),
          }

        when :edition_historical
          # Historical with "-" prefix: -3, -4
          return nil unless value.is_a?(Hash) && value[:edition_id]

          edition_id = value[:edition_id].to_s

          {
            edition: Components::Edition.new(type: "-", id: edition_id),
          }

        when :edition_r_with_space_letter
          # Revision with "r" prefix, space, and letter: r 5A (format preservation)
          # Used for patterns like "NIST SP 800-53 r5A"
          # NOTE: If there's an update component, the space was added by preprocessing
          return nil unless value.is_a?(Hash) && value[:edition_id] && value[:edition_letter]

          edition_id = value[:edition_id].to_s
          edition_letter = value[:edition_letter].to_s.upcase

          # Check if this is an embedded edition with update (space added by preprocessing)
          has_update = parsed_hash[:update_prefix] || parsed_hash[:update]

          if has_update
            # No original_prefix - space was added by preprocessing
            {
              edition: Components::Edition.new(type: "r", id: edition_id,
                                               additional_text: edition_letter),
            }
          else
            # Space was in original input - preserve format
            {
              edition: Components::Edition.new(type: "r", id: edition_id,
                                               additional_text: edition_letter,
                                               original_prefix: " r"),
            }
          end

        when :edition_r_with_space
          # Revision with "r" prefix and space: r 5 (format preservation)
          # Used for patterns like "NIST SP 800-53 r5"
          # NOTE: If there's an update component, the space was added by preprocessing
          # for patterns like "8115r1/upd" -> "8115 r1/upd", so don't set original_prefix
          return nil unless value.is_a?(Hash) && value[:edition_id]

          edition_id = value[:edition_id].to_s

          # Check if this is an embedded edition with update (space added by preprocessing)
          # Patterns like "8115r1/upd" become "8115 r1/upd" after preprocessing
          has_update = parsed_hash[:update_prefix] || parsed_hash[:update]

          if has_update
            # No original_prefix - space was added by preprocessing
            {
              edition: Components::Edition.new(type: "r", id: edition_id),
            }
          else
            # Space was in original input - preserve format
            {
              edition: Components::Edition.new(type: "r", id: edition_id,
                                               original_prefix: " r"),
            }
          end

        when :edition_id
          # Captured by edition_e, edition_r, edition_rev, edition_historical
          nil

        when :edition_date
          # Captured by edition_e_date
          nil

        # ========== LEGACY EDITION (for migration) ==========

        when :legacy_edition
          # Legacy edition patterns - will be phased out
          # For now, map to old edition_year/edition_month attributes
          nil # Handled by existing edition_year logic below

        when :edition_month, :edition_year, :edition_day, :edition_has_rev
          # These work together: edition_month + edition_year -> single edition ID
          # Skip processing if this is edition_month alone (will be processed with edition_year)
          return nil if type == :edition_month

          # Process edition_year, combining with edition_month if present
          return nil if value.nil? || value.to_s.strip.empty?

          # Build the edition ID from year and optional month
          edition_id = value.to_s # Start with year (e.g., "1985")

          # Add month if present (e.g., "Mar" -> "03", so "1985" + "03" = "198503")
          # For FIPS with day: "Sep30/1977" -> "19770930" (year + month + day)
          if parsed_hash[:edition_month]
            month_str = parsed_hash[:edition_month].to_s
            month_num = Date::ABBR_MONTHNAMES.index(month_str) ||
              Date::MONTHNAMES.index(month_str) ||
              month_str.to_i
            if month_num&.positive?
              # FIPS uses modern (numeric) date format; historical NBS keeps
              # month names like "April1909" instead of "190904".
              modern = Series.for(parsed_hash).modern_edition_date?
              if !modern && month_str.match?(/^[A-Z][a-z]+/) && edition_id.to_s.match?(/^\d{4}$/)
                # Historical NBS month+year format: preserve month name, use "-" type for special rendering
                edition_obj = Components::Edition.new(
                  type: "-",
                  id: "",
                  additional_text: "#{month_str}#{edition_id}",
                )
                return {
                  edition: edition_obj,
                  edition_year: edition_id.to_s,
                }
              else
                # Modern format (and FIPS): combine year and month as single number: 1985 + 03 = 198503
                edition_id = "#{edition_id}#{format('%02d', month_num)}"

                # For FIPS with day, append day as well: "Sep30/1977" -> "19770930"
                if modern && parsed_hash[:edition_day]
                  day_num = parsed_hash[:edition_day].to_s.to_i
                  if day_num.positive? && day_num <= 31
                    edition_id = "#{edition_id}#{format('%02d', day_num)}"
                  end
                end
              end
            end
          end

          # Create Edition component with type="e" (edition) and combined ID
          edition_obj = Components::Edition.new(type: "e", id: edition_id)

          # Return as hash to set edition and edition_year
          {
            edition: edition_obj, # Main attribute for tests
            edition_year: value.to_s, # Keep string for render logic
          }

        when :part
          # Part component - handle part number with optional addendum
          return nil if value.nil? || value.to_s.strip.empty?

          str_value = value.to_s.strip

          # Pattern: "1adde1" -> Part(value: "1"), addendum=true
          # Note: eN after add is discarded (not included in output per fixture)
          if str_value =~ /^(\d+)add(e\d+)$/
            {
              part: Components::Part.new(type: "pt", value: $1),
              addendum: "true",
            }
          elsif str_value =~ /^(\d+)add/
            {
              part: Components::Part.new(type: "pt", value: $1),
              addendum: "true",
            }
          else
            # Just a part number - return Part component with pt type
            { part: Components::Part.new(type: "pt", value: str_value) }
          end

        when :part_extracted
          # Legacy - this is now handled by :part
          nil

        when :edition_letter
          return nil if value.nil? || value.to_s.strip.empty?

          value.to_s

        when :public_draft
          return nil if value.nil?

          value.to_s

        when :draft
          # Extract draft number from "-draft N" pattern for pd rendering
          return nil if value.nil?

          str_value = value.to_s.strip
          return nil if str_value.empty?

          # Pattern: " -draft 2" or "-draft 2" -> extract "2" for pd rendering
          if str_value =~ /^\s*-draft\s+(\d+)$/
            { draft_number: $1 }
          # Pattern: " 2pd" -> already in pd format
          elsif str_value =~ /^\s*(\d+)pd$/
            { public_draft: $1 }
          # Other patterns (parenthetical, simple -draft)
          else
            str_value
          end

        when :addendum
          handle_addendum_cast(value)

        when :addendum_number
          return nil if value.nil? || value.to_s.strip.empty?

          value.to_s

        when :supplement_suffix
          # Return as hash to set supplement attribute (not supplement_suffix)
          { supplement: value.to_s }

        when :date
          # Date component per NIST spec
          return nil unless value.is_a?(Hash)

          # NEW: Check if this is historical edition pattern ("-April1909")
          # Parser captures as date with month + year, but semantically it's an edition
          if value[:date_month] && value[:date_year] && !value[:date_day]
            month_str = value[:date_month].to_s
            year_str = value[:date_year].to_s
            # If month is a word like "April", this is historical edition format
            if month_str.match?(/^[A-Za-z]+$/)
              return {
                edition: Components::Edition.new(type: "-",
                                                 additional_text: "#{month_str}#{year_str}"),
              }
            end
          end

          # Regular date processing
          value[:date_year]&.to_s
          value[:date_month]&.to_s
          value[:date_day]&.to_s

        else
          # Unknown types: return the original value for default processing
          # This allows hashes with arbitrary structures to be processed
          # e.g., second_number hash with number_only and edition_id
          value.is_a?(Hash) ? value : nil
        end
      end

      # Convert month name to month number
      # @param month_name [String] month abbreviation (Jan, Feb, Mar, etc.)
      # @return [Integer] month number (1-12)
      def month_name_to_number(month_name)
        month_map = {
          "Jan" => 1, "January" => 1,
          "Feb" => 2, "February" => 2,
          "Mar" => 3, "March" => 3,
          "Apr" => 4, "April" => 4,
          "May" => 5,
          "Jun" => 6, "June" => 6,
          "Jul" => 7, "July" => 7,
          "Aug" => 8, "August" => 8,
          "Sep" => 9, "Sept" => 9, "September" => 9,
          "Oct" => 10, "October" => 10,
          "Nov" => 11, "November" => 11,
          "Dec" => 12, "December" => 12,
        }
        month_map[month_name] || 1 # Default to January if not found
      end

      # Handle supplement casting with all its variants
      def handle_supplement_cast(value)
        return nil unless value

        if value.is_a?(Array) && value.empty?
          # Empty array means "supp" was present but no suffix
          ""
        else
          str_value = value.to_s.strip
          str_value.empty? ? nil : str_value
        end
      end

      # Handle addendum casting (number)
      def handle_addendum_cast(value)
        if value.is_a?(Hash)
          addendum_num = value[:addendum_number]&.to_s&.strip
          if addendum_num && !addendum_num.empty?
            { addendum_number: addendum_num }
          else
            { addendum: "true" }
          end
        else
          str_value = value.to_s.strip
          if str_value.empty?
            { addendum: "true" }
          else
            { addendum_number: str_value }
          end
        end
      end
    end
  end
end
