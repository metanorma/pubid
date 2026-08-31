# frozen_string_literal: true

# Shared helper module for testing identifier attributes
# Provides consistent attribute access patterns across all flavors
module AttributeHelper
  # Test that an identifier has expected attributes
  # @param identifier [Object] The identifier instance
  # @param expected_attrs [Hash] Hash of attribute names to expected values
  def expect_attributes(identifier, expected_attrs)
    expected_attrs.each do |attr, expected_value|
      actual_value = identifier.send(attr)
      expect(actual_value).to eq(expected_value),
                              "expected #{attr} to be #{expected_value.inspect}, got #{actual_value.inspect}"
    end
  end

  # Test that publisher attribute follows expected pattern
  # @param identifier [Object] The identifier instance
  # @param expected_publisher [String, Hash] Expected publisher (string or hash with :body)
  def expect_publisher(identifier, expected_publisher)
    publisher = identifier.publisher

    case expected_publisher
    when String
      expect(publisher).to eq(expected_publisher)
    when Hash
      expect(publisher.body).to eq(expected_publisher[:body]) if publisher.respond_to?(:body)
    end
  end

  # Test that code/number attribute follows expected pattern
  # @param identifier [Object] The identifier instance
  # @param expected_code [String] Expected code value
  def expect_code(identifier, expected_code)
    # Flavors that renamed the slug attribute (CSA, W3C) key on `number`.
    code = identifier.respond_to?(:code) ? identifier.code : identifier.number

    if code.respond_to?(:value)
      expect(code.value).to eq(expected_code)
    else
      expect(code).to eq(expected_code)
    end
  end

  # Test that year/date attribute follows expected pattern
  # @param identifier [Object] The identifier instance
  # @param expected_year [Integer, String] Expected year value
  def expect_year(identifier, expected_year)
    if identifier.respond_to?(:year)
      expect(identifier.year).to eq(expected_year)
    elsif identifier.respond_to?(:date)
      date = identifier.date
      actual_year = date.respond_to?(:year) ? date.year : date
      expect(actual_year).to eq(expected_year)
    end
  end

  # Unified attribute access helper
  # Normalizes access to common attributes across different identifier implementations
  # @param identifier [Object] The identifier instance
  # @param attr [Symbol] The attribute name
  # @return [Object] The normalized attribute value
  def get_attribute(identifier, attr)
    case attr
    when :publisher
      normalize_publisher(identifier.publisher)
    when :number, :code
      normalize_code(identifier.send(attr))
    when :year
      normalize_year(identifier)
    else
      identifier.send(attr)
    end
  end

  private

  def normalize_publisher(publisher)
    return publisher.body if publisher.respond_to?(:body)

    publisher
  end

  def normalize_code(code)
    return code.value if code.respond_to?(:value)

    code
  end

  def normalize_year(identifier)
    return identifier.year if identifier.respond_to?(:year)
    return identifier.date.year if identifier.respond_to?(:date) && identifier.date.respond_to?(:year)

    nil
  end
end
