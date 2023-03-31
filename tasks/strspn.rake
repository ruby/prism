# frozen_string_literal: true

desc "Generate yp_strspn_table"
namespace :generate do
  task :strspn do
    bits = {
      WHITESPACE: ["\t", "\n", "\v", "\f", "\r", " "],
      INLINE_WHITESPACE: ["\t", "\v", "\f", "\r", " "],
      DECIMAL_DIGIT: ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"],
      HEXIDECIMAL_DIGIT: ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f", "A", "B", "C", "D", "E", "F"],
      OCTAL_NUMBER: ["0", "1", "2", "3", "4", "5", "6", "7", "_"],
      DECIMAL_NUMBER: ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "_"],
      HEXIDECIMAL_NUMBER: ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "a", "b", "c", "d", "e", "f", "A", "B", "C", "D", "E", "F", "_"],
      REGEXP_OPTION: ["e", "i", "m", "n", "o", "s", "u", "x"]
    }
    
    table = +""
    (0...256).each_slice(16).with_index do |slice, row_index|
      row =
        slice.map do |codepoint|
          character = codepoint.chr
      
          value = 0
          bits.each_value.with_index do |characters, bit_index|
            value |= (1 << bit_index) if characters.include?(character)
          end
      
          "0x%02x," % value
        end
      
      table << "  #{row.join(" ")} // #{row_index.to_s(16).upcase}x\n"
    end

    bits.each_key.with_index do |name, bit_index|
      puts "#define YP_STRSPN_BIT_#{name} (1 << #{bit_index})"
    end

    puts "\nconst unsigned char yp_strspn_table[256] = {"
    puts "  // #{(0...16).map { |value| value.to_s(16).upcase }.join("     ")}"
    puts table
    puts "};\n\n"

    bits.each_key.with_index do |name, bit_index|
      puts "#undef YP_STRSPN_BIT_#{name}"
    end
  end
end
