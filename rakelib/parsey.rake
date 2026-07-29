# frozen_string_literal: true

class ParseYGrammar
  def initialize(source, filepath)
    stdlib_path = Lrama::Command::STDLIB_FILE_PATH
    stdlib = Lrama::Parser.new(File.read(stdlib_path), stdlib_path).parse

    grammar = Lrama::Parser.new(source, filepath).parse
    grammar.prepend_parameterized_rules(stdlib.parameterized_rules)
    grammar.prepare
    grammar.validate!

    @grammar = grammar
    @filepath = filepath
  end

  def strip
    stripped = "#{declarations}\n%%\n\n#{rules}\n%%\n"
    raise if shape != self.class.new(stripped, @filepath).shape
    stripped
  end

  protected

  # The shape of a parsed grammar used to validate that we have not accidentally
  # modified the automaton in some way while stripping the actions.
  def shape
    renames = build_renames(@grammar)
    rules =
      @grammar.rules.filter_map do |rule|
        lhs = rule.lhs.id.s_value
        next if lhs == "$accept" || lhs.match?(/\A[@$]/)

        [symbol_name(rule.lhs, renames), rule.rhs.map { |sym| symbol_name(sym, renames) }, rule.precedence_sym&.id&.s_value]
      end

    precedence =
      @grammar.terms.filter_map do |term|
        if (precedence = term.precedence)
          [term.id.s_value, precedence.type, precedence.precedence]
        end
      end

    [rules, precedence.sort, @grammar.expect]
  end

  private

  def symbol_name(symbol, renames)
    s_value = symbol.id.s_value
    s_value.match?(/\A[@$]/) ? "{}" : renames.fetch(s_value, s_value)
  end

  def declarations
    out = +""

    @grammar.define.sort.each do |key, value|
      out << "%define #{key}#{" #{value}" if value}\n"
    end

    out << "%expect #{@grammar.expect}\n"
    out << "%parse-param {#{@grammar.parse_param}}\n"
    out << "%lex-param {#{@grammar.lex_param}}\n"
    out << "\n"

    @grammar.terms.each do |term|
      s_value = term.id.s_value

      # Token names lrama defines internally; they are never declared by a
      # grammar and must not be re-declared by the emission.
      next if %w[error YYerror YYUNDEF].include?(s_value) || !s_value.match?(/\A[a-zA-Z_]/)

      out << "%token #{s_value} #{term.token_id}"
      out << " #{term.alias_name}" if term.alias_name
      out << "\n"
    end
    out << "\n"

    levels = @grammar.terms.select(&:precedence).group_by { |term| term.precedence.precedence }
    levels.sort.each do |_level, terms|
      out << "%#{terms.first.precedence.type} #{terms.map { |term| term.id.s_value }.join(" ")}\n"
    end

    start = @grammar.rules.first.rhs.first.id.s_value
    out << "\n%start #{start}\n"
    out
  end

  def rules
    out = +""
    ind = " " * 16

    renames = build_renames(@grammar)
    previous = nil

    @grammar.rules.each do |rule|
      lhs = rule.lhs.id.s_value
      next if lhs == "$accept" || lhs.match?(/\A[@$]/)

      alts = rule.rhs.map { |sym| symbol_name(sym, renames) }
      alts = ["%empty"] if alts.empty?

      # A lone {} in final position would be the rule action rather than a
      # hidden nonterminal; a mid-rule action ending its rule needs a trailing
      # empty action after it to keep its own reduction.
      alts << "{}" if alts.last == "{}"

      # The default rule precedence is the last terminal's; only explicit
      # overrides need re-emitting.
      last_term = rule.rhs.reverse.find(&:term?)
      if rule.precedence_sym && rule.precedence_sym != last_term
        alts << "%prec #{rule.precedence_sym.id.s_value}"
      end

      lhs = renames.fetch(lhs, lhs)
      if lhs == previous
        out << "#{ind}| #{alts.join(" ")}\n"
      else
        out << "#{ind};\n\n" unless previous.nil?
        out << "#{lhs}: #{alts.join(" ")}\n"
        previous = lhs
      end
    end

    out << "#{ind};\n"
    out
  end

  # Parameterized-rule instantiations get generated names that are not always
  # valid grammar identifiers (e.g., option_'\n').
  def build_renames(grammar)
    @grammar.nterms.each_with_object({}) do |nterm, renames|
      s_value = nterm.id.s_value
      if !s_value.match?(/\A[@$]/) && !s_value.match?(/\A[a-zA-Z_][a-zA-Z0-9_]*\z/)
        renames[s_value] = s_value.gsub(/[^a-zA-Z0-9_]/, "_")
      end
    end
  end
end

directory "tmp"
directory "tmp/ruby" => "tmp" do |task|
  mkdir_p task.name
  chdir task.name do
    sh "git init"
    sh "git remote add origin https://github.com/ruby/ruby"
  end
end

directory "grammars"
["3.3", "3.4", "4.0", "master"].each do |version|
  desc "Fetch the #{version} parse.y grammar"
  file "grammars/#{version}.y" => ["tmp/ruby", "grammars"] do |task|
    chdir "tmp/ruby" do
      ref = version

      if ref != "master"
        major, minor = ref.split(".")
        refs = `git -c versionsort.suffix=_preview -c versionsort.suffix=_rc ls-remote --refs --sort=-version:refname origin "v#{major}_#{minor}_*" "v#{major}.#{minor}.*"`
        ref = refs[%r{refs/tags/(\S+)}, 1] or raise
      end

      sh "git fetch --depth=1 origin #{ref}"
      sh "git reset --hard FETCH_HEAD"
    end

    sh "ruby -p tmp/ruby/tool/id2token.rb < tmp/ruby/parse.y > #{task.name}"

    require "lrama"
    File.write(task.name, ParseYGrammar.new(File.read(task.name), task.name).strip)
  end
end
