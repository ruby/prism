# frozen_string_literal: true

desc "Generate the lookup tables for pm_char.c"
namespace :generate do
  task :char do
    puts "static const uint8_t pm_char_table[256] = {"
    puts "//#{(0...16).map { |value| value.to_s(16).upcase }.join("  ")}"

    (0...256).each_slice(16).with_index do |slice, row_index|
      row =
        slice.map do |codepoint|
          character = codepoint.chr

          value = 0
          value |= (1 << 0) if ["\t", "\n", "\v", "\f", "\r", " "].include?(character)
          value |= (1 << 1) if ["\t", "\v", "\f", "\r", " "].include?(character)
          value |= (1 << 2) if ["e", "i", "m", "n", "o", "s", "u", "x"].include?(character)

          "%d," % value
        end

      puts "  #{row.join(" ")} // #{row_index.to_s(16).upcase}x\n"
    end

    puts "};\nstatic const uint8_t pm_number_table[256] = {"
    puts "  // #{(0...16).map { |value| value.to_s(16).upcase }.join("     ")}"

    (0...256).each_slice(16).with_index do |slice, row_index|
      row =
        slice.map do |codepoint|
          character = codepoint.chr

          value = 0
          value |= (1 << 0) if ("0".."1").include?(character)
          value |= (1 << 1) if ("0".."1").include?(character) || character == "_"
          value |= (1 << 2) if ("0".."7").include?(character)
          value |= (1 << 3) if ("0".."7").include?(character) || character == "_"
          value |= (1 << 4) if ("0".."9").include?(character)
          value |= (1 << 5) if ("0".."9").include?(character) || character == "_"
          value |= (1 << 6) if ("0".."9").include?(character) || ("a".."f").include?(character) || ("A".."F").include?(character)
          value |= (1 << 7) if ("0".."9").include?(character) || ("a".."f").include?(character) || ("A".."F").include?(character) || character == "_"

          "0x%02x," % value
        end

      puts "  #{row.join(" ")} // #{row_index.to_s(16).upcase}x\n"
    end
    puts "};"
  end
end
