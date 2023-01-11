# frozen_string_literal: true

require "test_helper"
require "yaml"

class ConfigCommentTest < Test::Unit::TestCase
  include YARP::DSL

  YAML.load_file(File.expand_path("../config.yml", __dir__)).fetch("nodes").each do |node|
    test "node #{node["name"]} has correct comment underline" do
      code = node["comment"].lines.filter { |l| l.start_with?("    ") }

      code_lines = []
      underlined_sections = []
      underlined_indexes = []
      code.each_with_index do |line, index|
        if line.match?(/^[\W\^]+$/) # underline line
          start = 0
          finish = 0
          line.chars.each_with_index do |char, char_index|
            if start.zero?
              if char == "^"
                start = char_index
                finish = char_index+1
              end
            else
              if char == "^"
                finish = char_index+1
              end
            end
          end
          underlined_sections << code[index - 1][start..finish]
          s = code_lines.join("\n").chars.size - code_lines.last.chars.size + start
          e = code_lines.join("\n").chars.size - code_lines.last.chars.size + finish
          underlined_indexes << [s, e]
        else
          code_lines << line
        end
      end

      code_str = code_lines.join("\n")

      yarp_underlines = []
      YARP.parse(code_str).node.statements.child_nodes.each do |yarv_node|
        if node["name"] == "DefNode"
          next
        end

        if "YARP::" + node["name"] == yarv_node.class.name
          s = yarv_node.location.start_offset
          e = yarv_node.location.end_offset
          yarp_underlines << [s, e]
        end
      end

      yarp_underlines.zip(underlined_indexes).each do |yarp_undreline, comment_underline|
        assert_equal code_str[comment_underline[0]...comment_underline[1]], code_str[yarp_undreline[0]...yarp_undreline[1]]
      end
    end
  end
end
