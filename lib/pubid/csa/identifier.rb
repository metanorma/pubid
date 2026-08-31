# frozen_string_literal: true

module Pubid
  module Csa
    # Common base class for EVERY CSA identifier — the single-document types
    # through SingleIdentifier, and the container types (WrapperIdentifier,
    # CompositeIdentifier, Bundled, Combined) directly. So every CSA identifier
    # is `is_a?(Pubid::Csa::Identifier)` natively and gets the shared
    # polymorphic `from_hash`, `#root`, `#exclude` and MR rendering. The
    # containers used to be separate Lutaml::Model types, which is what made
    # `root.number` raise rather than return the relaton index key.
    class Identifier < ::Pubid::Identifier
      def self.parse(input)
        if input.length > Pubid::MAX_INPUT_LENGTH
          raise ArgumentError, Pubid::INPUT_TOO_LONG_MESSAGE
        end

        # Filter out comments
        if input.start_with?("#")
          raise Parslet::ParseFailed, "Not a CSA identifier (comment): #{input}"
        end

        # Filter out non-standards (memberships, courses, newsletters)
        if input.match?(/^CSA (Communities|Group|Learning|OnDemand|Update)/)
          raise Parslet::ParseFailed, "Not a CSA standard: #{input}"
        end

        # Preprocessing: normalize CEI to IEC (French name)
        input = input.gsub("CEI/IEC", "IEC").gsub(/\bCEI\b/, "IEC")

        # Detect CAN/ wrapper (Canadian adoption)
        if input.start_with?("CAN/")
          # Check if this is actually a bundled/combined identifier with + or /
          # that should NOT be wrapped in CanadianAdopted
          wrapped_input = input.sub(/^CAN\//, "")

          # Check for bundled (+) or combined (/ or ,) patterns that should remain as-is
          # These should be parsed normally, with publisher prefix applied to each part
          # Patterns to detect:
          # 1. Bundled: + separator (e.g., "CSA B127.1:99 + B127.2:99")
          # 2. Combined with space: / separator with space before CSA- (e.g., "CSA A23.1:24/CSA A23.2:24")
          # 3. Combined with CAN/CSA-: / separator with CSA- appearing multiple times (e.g., "CSA-B138.1-17/CSA-B138.2-17")
          if wrapped_input.include?("+") ||
              (wrapped_input.include?("/") && wrapped_input.match?(/\s+CSA-/)) ||
              (wrapped_input.include?("/") && wrapped_input.scan("CSA-").length > 1)
            # This is a bundled or combined identifier - parse normally and add prefix
            # Normalize CSA- to CSA (with space) for parsing
            normalized = wrapped_input.sub(/^CSA-/, "CSA ")
            normalized = normalized.gsub("CAN/CSA-", "CSA ").gsub("CAN3-",
                                                                  "CSA ")
            normalized = normalized.gsub(/\s+/, " ").strip

            # Parse normally (will create Bundled or Combined identifier)
            tree = Parser.new.parse(normalized)
            result = build!(tree, input)

            # Apply CAN/CSA- prefix to the appropriate parts
            set_publisher_prefix(result, "CAN/CSA-")

            # Handle reaffirmation if present
            if (wrapped_input =~ /\(R(\d{4})\)/) && result.class.attributes.key?(:reaffirmation)
              result.reaffirmation = $1
            end

            return result
          end

          # This is a standard single identifier wrapped in CanadianAdopted
          # Remove CAN/ prefix (already done above)

          # Extract reaffirmation FIRST (before any other processing)
          reaffirm_year = nil
          reaffirmation_was_4digit = false # Track original format
          if wrapped_input =~ /\(R(\d{2,4})\)/
            reaffirm_year = $1
            reaffirmation_was_4digit = ($1.length == 4) # Track if original was 4-digit
            # Convert 2-digit year to 4-digit if needed
            if reaffirm_year.length == 2
              year_int = reaffirm_year.to_i
              reaffirm_year = year_int < 50 ? "20#{reaffirm_year}" : "19#{reaffirm_year}"
            end
            wrapped_input = wrapped_input.sub(/\s*\(R\d{2,4}\)/, "")
          end

          # Detect and preserve original format (CSA- vs CSA)
          # Also track that this is a CAN/CSA- identifier (not just CSA-)
          original_prefix = if wrapped_input.start_with?("CSA-")
                              "CSA-"
                            elsif wrapped_input.start_with?("CSA ")
                              "CSA"
                            end
          is_can_csa = true # Track that this has the CAN/ wrapper

          # Normalize CSA- to CSA  (with space) for parsing
          wrapped_input = wrapped_input.sub(/^CSA-/, "CSA ")

          # Parse the wrapped identifier recursively
          base = parse(wrapped_input)

          # NOTE: Series identifiers should be wrapped in CanadianAdopted when
          # they have CAN/CSA- prefix. The Series will handle rendering correctly.
          # Do NOT return Series directly - always wrap in CanadianAdopted.

          # Set publisher prefix on wrapped identifier
          # For Series identifiers with CAN/ wrapper, use full "CAN/CSA-" prefix
          # For other identifiers, use the detected original_prefix ("CSA-" or "CSA")
          if base.class.attributes.key?(:publisher_prefix)
            if is_can_csa && base.is_a?(Identifiers::Series)
              # Series gets full "CAN/CSA-" prefix for proper rendering
              base.publisher_prefix = "CAN/CSA-"
            elsif original_prefix
              # For Combined identifiers, set on the primary designation
              if base.is_a?(Identifiers::Combined) && base.identifiers&.first
                primary = base.identifiers.first
                if primary.class.attributes.key?(:publisher_prefix)
                  primary.publisher_prefix = original_prefix
                end
              else
                # For non-Combined identifiers, set directly
                base.publisher_prefix = original_prefix
              end
            end
          end

          # Set reaffirmation on base if it has the attribute
          if base.class.attributes.key?(:reaffirmation) && reaffirm_year
            base.reaffirmation = reaffirm_year
            if base.class.attributes.key?(:original_reaffirmation_4digit)
              base.original_reaffirmation_4digit = reaffirmation_was_4digit
            end
          end

          # Create CanadianAdoptedIdentifier wrapper
          result = Identifiers::CanadianAdopted.new
          result.base = base
          result.reaffirmation = reaffirm_year if reaffirm_year

          return result
        end

        # Detect CAN3- wrapper (historical Canadian adoption)
        if input.start_with?("CAN3-")
          # This is a historical Canadian adoption - parse as wrapper
          # Remove CAN3- prefix
          wrapped_input = input.sub(/^CAN3-/, "CSA ")

          # Detect year format before normalization (CAN3- standards use dash format)
          # Format: CAN3-Z299.0-86 (uses dash, not colon)
          has_dash_year = wrapped_input.match?(/-\d{2}\b/) # Match -86, -05, etc. (2-digit years)

          # Extract reaffirmation FIRST (before any other processing)
          reaffirm_year = nil
          reaffirmation_was_4digit = false # Track original format
          if wrapped_input =~ /\(R(\d{2,4})\)/
            reaffirm_year = $1
            reaffirmation_was_4digit = ($1.length == 4) # Track if original was 4-digit
            # Convert 2-digit year to 4-digit if needed
            if reaffirm_year.length == 2
              year_int = reaffirm_year.to_i
              reaffirm_year = year_int < 50 ? "20#{reaffirm_year}" : "19#{reaffirm_year}"
            end
            wrapped_input = wrapped_input.sub(/\s*\(R\d{2,4}\)/, "")
          end

          # Parse the wrapped identifier recursively
          base = parse(wrapped_input)

          # Set year_format for dash format identifiers (preserve original 2-digit year)
          if has_dash_year && base.class.attributes.key?(:year_format)
            base.year_format = "dash"
            # Mark original year as 2-digit so renderer converts back (1986 → 86)
            if base.class.attributes.key?(:original_year_4digit)
              base.original_year_4digit = false
            end
          end

          # Check if this is a Series identifier - return it directly with CAN3- prefix
          # Series identifiers are complete identifier types and handle the prefix themselves
          # They don't need to be wrapped in CanadianAdopted
          if base.is_a?(Identifiers::Series)
            base.publisher_prefix = "CAN3-"
            base.reaffirmation = reaffirm_year if reaffirm_year
            base.original_reaffirmation_4digit = reaffirmation_was_4digit
            return base
          end

          # Set CAN3- as publisher prefix on wrapped identifier
          if base.class.attributes.key?(:publisher_prefix)
            base.publisher_prefix = "CAN3-"
          end

          # Set reaffirmation on base if it has the attribute
          if base.class.attributes.key?(:reaffirmation) && reaffirm_year
            base.reaffirmation = reaffirm_year
            if base.class.attributes.key?(:original_reaffirmation_4digit)
              base.original_reaffirmation_4digit = reaffirmation_was_4digit
            end
          end

          # Create CanadianAdoptedIdentifier wrapper
          result = Identifiers::CanadianAdopted.new
          result.base = base
          result.reaffirmation = reaffirm_year if reaffirm_year

          return result
        end

        # Detect CSA adoption of international standards
        # Examples: CSA ISO/IEC TR 12785-3:15, CSA CISPR 16-1-1:18, CSA IEC 60601-1:08
        #          CSA CEI/IEC 61000-4-28-01 (bilingual)
        if input.match?(/^CSA (ISO\/IEC|CEI\/IEC|CISPR|IEC|CEI|ISO)\s/)
          # This is CSA adoption of international standard
          # Extract the wrapped standard portion
          wrapped_input = input.sub(/^CSA\s+/, "")

          # Extract reaffirmation FIRST (before parsing)
          reaffirm_year = nil
          if wrapped_input =~ /\(R(\d{2,4})\)/
            reaffirm_year = $1
            # Convert 2-digit year to 4-digit if needed
            if reaffirm_year.length == 2
              year_int = reaffirm_year.to_i
              reaffirm_year = year_int < 50 ? "20#{reaffirm_year}" : "19#{reaffirm_year}"
            end
            wrapped_input = wrapped_input.sub(/\s*\(R\d{2,4}\)/, "")
          end

          # Convert 2-digit years to 4-digit for external parser
          # :15 → :2015, :04 → :2004
          if wrapped_input =~ /:(\d{2})\b/
            short_year_str = $1 # Keep as string "04", "15", etc.
            short_year_int = short_year_str.to_i
            # Determine century: 00-49 → 2000s, 50-99 → 1900s
            full_year = short_year_int < 50 ? "20#{short_year_str}" : "19#{short_year_str}"
            wrapped_input = wrapped_input.sub(/:#{short_year_str}\b/,
                                              ":#{full_year}")
          end

          # Convert CSA amendment format to ISO/IEC format
          # /A1:22 → /Amd 1:2022, /A1-22 → /Amd 1-2022
          # Also handle 2-digit and 4-digit amendment years (convert to 4-digit)
          # Note: In gsub blocks with string regex, we must use $1, $2, $3
          # because the block receives a String, not MatchData
          wrapped_input = wrapped_input.gsub(%r{/A(\d+)([:/-])(\d{2,4})\b}) do
            amendment_num = $1
            separator = $2
            amend_year_str = $3
            amend_year_int = amend_year_str.to_i
            # Convert 2-digit year to 4-digit if needed
            if amend_year_str.length == 2
              amend_full_year = amend_year_int < 50 ? "20#{amend_year_str}" : "19#{amend_year_str}"
            else
              amend_full_year = amend_year_str
            end
            "/Amd #{amendment_num}#{separator}#{amend_full_year}"
          end

          # Parse with appropriate flavor parser. The helper probes several
          # flavors and reports failure with nil; the public contract is a
          # raise, so translate here.
          base = parse_external_standard(wrapped_input)
          unless base
            raise Parslet::ParseFailed, "Unparseable adopted standard: #{input}"
          end

          # Create CsaAdoptedIdentifier wrapper
          result = Identifiers::CsaAdopted.new
          result.base = base
          result.reaffirmation = reaffirm_year if reaffirm_year

          return result
        end

        # Detect package identifiers
        # Examples: CSA Z662:23 PACKAGE INCLUDES: +1 (PDF & ESA)
        #           CSA B149.1:25 Code, Handbook & Training Package (materials BEFORE keyword)
        #           CSA B149.1:20 PACKAGE (PDF + PRINT) (no materials)
        #           CSA B108:23 PACKAGE (no trailing space)
        if input.match?(/\sPACKAGE\b/i)
          # Handle two formats:
          # 1. {base} PACKAGE {materials} - materials after keyword
          # 2. {base} {materials} PACKAGE - materials before keyword

          # Check if materials come after PACKAGE keyword
          # Match: "CSA Z662:23 PACKAGE INCLUDES: +1" or "CSA B149.1:20 PACKAGE (PDF + PRINT)"
          case input
          when /\sPACKAGE\s+[A-Z]/i
            # Format: {base} PACKAGE {materials}
            # Extract materials after PACKAGE keyword
            base_input, package_materials = input.split(/\s+PACKAGE\s+/i, 2)
            base_input = base_input.strip
            package_materials = package_materials ? package_materials.strip : ""
            materials_after = true
          when /:(\d{2,4})(\s+[^P]+)\s+PACKAGE/i
            # Format: {base} PACKAGE or {base} {materials} PACKAGE
            # Examples: "C22.1-15 PACKAGE" (no materials), "CSA B149.1:25 Code, Handbook & Training Package"

            # Check if there's a year followed by materials before PACKAGE
            # Must check this BEFORE the generic "{base} PACKAGE" pattern
            $1
            $2

            # Check if this is a combined identifier (has comma with CSA after it)
            # Pattern: ", CSA" or ", CAN" which indicates combined identifier
            if input.match?(/,\s+CSA/)
              # For combined identifiers, we need to extract everything before "& Training Package"
              # The base is the combined identifier, materials is just "& Training Package"
              combined_match = input.match(/^(.+?)(\s+&[^P]+)\s+PACKAGE$/i)
              if combined_match
                base_input = combined_match[1].strip
                package_materials = "#{combined_match[2].strip} Package" # Keep "& Training Package"
              else
                # Fallback to year-based extraction
                year_match = input.match(/:\d{2,4}/)
                if year_match
                  base_input = input[0..(year_match.end(0) - 1)]
                  materials_input = input[year_match.end(0)..].strip
                  package_materials = materials_input
                end
              end
            else
              # Standard single identifier with materials before PACKAGE
              year_match = input.match(/:\d{2,4}/)
              if year_match
                base_input = input[0..(year_match.end(0) - 1)]
                # Materials is everything between base and PACKAGE - keep the "Package" suffix for correct capitalization
                materials_input = input[year_match.end(0)..].strip
                package_materials = materials_input # Keep full materials including "Package" suffix
                base_input = base_input.strip
              end
            end
            materials_after = false
          # Format: {base} {materials} PACKAGE - "CSA B149.1:25 Code, Handbook & Training Package"
          # OR: Combined identifier with package: "CSA B149.1:25, CSA B149.2:25 & Training Package"
          when /^(.+?)\s+PACKAGE\s*$/i
            # Format: {base} PACKAGE (no materials) - "C22.1-15 PACKAGE"
            # Treat PACKAGE as the package description
            base_input = input.sub(/\s+PACKAGE\s*$/i, "").strip
            package_materials = "" # No additional materials
            materials_after = true
          else
            # Fallback: try parsing incrementally
            tokens = input.split(/\s+/)
            base_input = ""
            tokens.each do |token|
              break if token.match?(/^PACKAGE$/i)

              test_input = base_input.empty? ? token : "#{base_input} #{token}"
              break unless try_parse(test_input)

              base_input = test_input
            end

            # Extract materials as everything between base and PACKAGE
            if base_input && base_input.length < input.length
              materials_input = input[base_input.length..].strip
              package_materials = materials_input.sub(/\s+PACKAGE\s*$/i,
                                                      "").strip
              materials_after = !package_materials.empty?
            end
          end

          # Parse the base identifier recursively. An unparseable base is a
          # failed package, not a nil.
          if base_input.nil? || base_input.empty?
            raise Parslet::ParseFailed, "Unparseable package base: #{input}"
          end

          base = parse(base_input)

          # Create PackageIdentifier
          result = Identifiers::Package.new
          result.base = base
          # Set materials if present
          if package_materials && !package_materials.empty?
            result.package_materials = package_materials
          end
          result.package_keyword = "PACKAGE"
          # Set materials_after_keyword flag based on which format we detected
          result.materials_after_keyword = materials_after

          return result
        end

        # Legacy handling for CAN/CSA- and CAN3- (will be migrated to proper classes later)
        # Detect original publisher prefix before normalization
        publisher_prefix = if input.start_with?("CAN/CSA-")
                             "CAN/CSA-"
                           elsif input.start_with?("CAN3-")
                             "CAN3-"
                           elsif input.start_with?("CSA ")
                             "CSA"
                           end

        # Detect year format before normalization
        # CAN/CSA- standards use dash format: CAN/CSA-C22.2-05
        # Modern CSA standards use colon format: CSA B149:20
        has_dash_year = input.match?(/-\d{2}\b/)

        # Normalize CAN/CSA- and CAN3- to CSA (global replacement for combined identifiers)
        normalized = input.gsub("CAN/CSA-", "CSA ")
        # Normalize CAN3- to CSA (historical prefix)
        normalized = normalized.gsub("CAN3-", "CSA ")

        tree = Parser.new.parse(normalized)
        result = build!(tree, input)

        # Set publisher prefix if detected
        set_publisher_prefix(result, publisher_prefix) if publisher_prefix

        # Set year format if detected as dash and not already set
        result.year_format = "dash" if has_dash_year && result.year_format.nil?

        result
      rescue Parslet::ParseFailed => e
        raise e
      end

      # Build a parse tree into an identifier, or fail loudly.
      #
      # Builder#build can return nil for a tree it recognises but cannot map
      # to a class. `parse` must return an identifier or raise — every flavor
      # but `api` already honours that — because a nil surfaces in the caller
      # as a NoMethodError far from the input that caused it, rather than as a
      # catchable parse failure.
      def self.build!(tree, input)
        Builder.new.build(tree) ||
          raise(Parslet::ParseFailed, "Unparseable CSA identifier: #{input}")
      end

      # Probe whether a string parses. The package base scan walks
      # progressively longer prefixes and keeps the longest that succeeds, so
      # it is the one caller that genuinely wants a nil rather than a raise.
      def self.try_parse(input)
        parse(input)
      rescue Parslet::ParseFailed, ArgumentError
        nil
      end

      def self.set_publisher_prefix(obj, prefix)
        # Set on main object if it has the attribute
        if obj.class.attributes.key?(:publisher_prefix)
          obj.publisher_prefix = prefix
        end

        # Set on combined identifier parts. The primary designation always
        # takes the prefix; a trailing one only when it printed a publisher of
        # its own (a bare continuation must stay bare).
        if obj.is_a?(Identifiers::Combined)
          Array(obj.identifiers).each_with_index do |part, index|
            next unless part.class.attributes.key?(:publisher_prefix)
            next if index.positive? &&
              !(part.class.attributes.key?(:has_publisher) && part.has_publisher)

            part.publisher_prefix = prefix
          end
        end

        # Set on bundled identifier base
        if obj.is_a?(Identifiers::Bundled) && obj.base
          set_publisher_prefix(obj.base, prefix)
        end
      end

      def self.parse_external_standard(input)
        # Try ISO/IEC first (most common)
        if input.match?(/^(ISO\/IEC|ISO|IEC|CEI|CEI\/IEC)\s/)
          begin
            # Normalize CEI/IEC to IEC for parsing (CEI is French for IEC)
            normalized_input = input.sub(/^CEI\/IEC/, "IEC")
            return Pubid::Iso.parse(normalized_input)
          rescue StandardError
            return nil
          end
        end

        # Try CISPR (uses IEC parser)
        if input.match?(/^CISPR\s/)
          begin
            return Pubid::Iec.parse(input)
          rescue StandardError
            return nil
          end
        end

        nil
      end

      # CSA stores the publication year in its own plain `year` string
      # attribute (not a `Components::Date`), so the base `#exclude`'s
      # `:year`->`:date` remap nils the unused inherited `date` and leaves
      # `year` intact. Override to nil `year` (and its formatting metadata)
      # when `:year`/`:date` is excluded, so a partial (year-less) CSA
      # reference is a year wildcard under `matches?(row, ignore: [:year])`.
      # The metadata attrs (`year_format`, `year_prefix`,
      # `original_year_4digit`, `french`) are year-derived — a year-less
      # parse leaves them nil/false, so they must be reset here too or `==`
      # would still differ. `french` in particular is only ever set from a
      # `:F` year prefix (the French-edition form `CSA B149.1:F20`), so a
      # bare `CSA B149.1` reference must wildcard it to match both the
      # English and French editions of a document number. `super` preserves
      # the base recursion into nested identifiers (adoption wrappers
      # delegate their year to an inner id and lack a `year` accessor, hence
      # the `respond_to?` guard). Mirrors BIPM.
      def exclude(*args)
        result = super
        year_keys = args & %i[year date]
        if !year_keys.empty? && result.respond_to?(:year=)
          result.year = nil
          result.year_format = nil
          result.year_prefix = nil
          result.original_year_4digit = false
          result.french = nil
        end
        result
      end

      # CSA encodes its identity across many shape-specific attributes
      # (`publisher_prefix`, `number`, `no_number`, `series`, `series_prefix`,
      # `package`, `reaffirmation`, `year` with prefix/format/French markers,
      # etc.) that the generic MrString renderer doesn't know about. The
      # CSA `to_s` already round-trips losslessly through the CSA parser, so
      # MR mirrors it: ` ` → `.`, `:` → `.` (so the year never looks like
      # another code segment), `/` → `-` (CAN/CSA- prefix), then lowercased
      # to match the all-lowercase MR convention (issue #142).
      #
      # Those three are the SEMANTIC mappings — they carry CSA's segment
      # structure. Everything else is then neutralised by CHARSET, not by an
      # enumerated escape list, so a character that appears in a future
      # reference cannot leak into what `to_slug` hands a filesystem. CSA
      # references really do carry `(`, `)`, `,`, `&` and `+` today
      # (`CSA C22.2 NO. 100:14 (R2024)`, `… Code, Handbook & Training
      # Package`, `… + A1:15`), and the old `tr` chain let all of them
      # through — 601 of 816 slugs were not filename-safe. The BIPM `mr_slug`
      # precedent.
      def to_mr_string
        to_s
          .downcase
          .tr(" ", ".").tr(":", ".").tr("/", "-")
          .gsub(/[^a-z0-9._-]+/, "-")
          .gsub(/\A[-.]+|[-.]+\z/, "")
      end

      def to_slug
        to_mr_string
      end
    end
  end
end
