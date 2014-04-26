#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

require './rdparse.rb'
require './nodes.rb'

class PseudoCode
  def initialize(scope=Scope.new)
    @parser = Parser.new("pseudo parser") do
      token(/#.*?$/)      # Comments
      token(/".*?"/)      { |m| m.to_s } # Strings
      token(/-?\d+\.\d+/) { |m| m.to_f } # Floats
      token(/-?\d+/)      { |m| m.to_i } # Integers
      token(/\w+/)        { |m| m }      # Variables, keywords, etc
      token(/\n+/)        # :newline, :indent and :dedent tokens
      token(/[^ ]/)       { |m| m } # Non-space characters
      token(/ /)          # Throw away spaces

      start :program do
        match(:top_level_statements) { |m| ProgramNode.new(m, scope) }
      end

      rule :top_level_statements do
        match(:top_level_statements, :func_decl) { |m, n| m << n }
        match(:top_level_statements, :statements) { |m, n| m + n }
        match(:empty) { [] }
      end

      rule :statements do
        match(:newline, :statements) { |_, a| a }
        match(:statements, :newline, :statement) { |a, _, b| a << b }
        match(:statements, :newline) { |a, _| a }
        match(:statement) { |m| [m] }
      end

      rule :statement do
        match('write', :expression_list) { |_, m| WriteNode.new(m) }
        match('read', 'to', :identifier) { |_, _, var| InputNode.new(var_name) }
        match(:if) { |a| a }
        match(:while) { |a| a }
        match(:for_each) { |a| a }
        match('return', :expression) { |_, m| ReturnValue.new(m) }
        match(:assignment) { |a, b, c| AssignmentNode.new(a, b, c) }
        match(:func_exec) { |m| m }
        match(:newline)
      end

      rule :if do
        match('if', :bool_expr, 'then', :newline,
              :indent, :statements, :dedent, :if_else) do
          |_, if_expr, _, _, _, if_stmts, _, elseif|
          ConditionNode.new(if_expr, if_stmts, elseif)
        end
      end

      rule :if_else do
        match(:newline, 'else', 'if', :bool_expr, 'then', :newline,
              :indent, :statements, :dedent, :if_else) do
          |_, _, _, if_expr, _, _, _, if_stmts, _, elseif| 
          ConditionNode.new(if_expr, if_stmts, elseif)
        end
        match(:newline, 'else', :newline, :indent, :statements, :dedent) do
          |_, _, _, _, stmts, _| ConditionNode.new(true, stmts)
        end
        match(:empty)
      end

      rule :while do
        match('while', :bool_expr, 'do', :newline,
              :indent, :statements, :dedent) do |_, expr, _, _ , _, stmts, _|
          WhileNode.new(expr, stmts)
        end
      end

      rule :for_each do
        match('for', 'each', :identifier, :foreach_list, 'do', :newline,
              :indent, :statements, :dedent) do
          |_, _, var, iterator, _, _, _, stmts, _|
          ForEachNode.new(var, iterator, stmts)
        end
      end

      rule :foreach_list do
        match('in', :expression) { |_, iterator| iterator }
        match('from', :variable_get, 'to', :variable_get) do |_, start, _, stop|
          FromNode.new(start, stop); end
        match('from', :variable_get, 'to', :integer) do |_, start, _, stop|
          FromNode.new(start, stop); end
        match('from', :integer, 'to', :variable_get) do |_, start, _, stop|
          FromNode.new(start, stop); end
        match('from', :integer, 'to', :integer) do |_, start, _, stop|
          FromNode.new(start, stop); end
      end

      rule :assignment do
        match(:identifier, 'equals', :expression) { |a, _, b| [a, b] }
        match('increase', :identifier, 'by', :expression) { |_, a, _, b| [a, b, "+="] }
        match('decrease', :identifier, 'by', :expression) { |_, a, _, b| [a, b, "-="] }
        match('multiply', :identifier, 'by', :expression) { |_, a, _, b| [a, b, "*="] }
        match('divide', :identifier, 'by', :expression) { |_, a, _, b| [a, b, "/="] }
      end

      rule :expression do
        match(:func_exec) { |m| m }
        match(:bool_expr) { |m| m }
        match(:aritm_expr) { |m| m }
        match(:variable_get) { |m| m }
        match(:string) { |m| m }
        match(:array) { |m| m }
      end

      rule :expression_list do
        match(:expression_list, ',', :expression) { |a, _, b| a << b }
        match(:expression) { |m| ArrayNode.new([m]) }
      end

      rule :bool_expr do
        match(:bool_expr, 'and', :simple_bool) do |a, b, c|
          BoolNode.new(a, b, c); end
        match(:bool_expr, 'or', :simple_bool) do |a, b, c| 
          BoolNode.new(a, b, c); end
        match(:simple_bool) { |m| m }
      end

      rule :simple_bool do
        match('not', :bool_expr) { |_, e| BoolNode.new(e, "not") }
        match('true') { BoolNode.new(true) }
        match('false') { BoolNode.new(false) }
        match(:comparison) { |m| m }
      end

      rule :comparison do
        match(:aritm_expr, 'is', :comparison_tail) do |e, _, comp_node|
          comp_node.set_lh(e); end
        match(:aritm_expr) { |m| m }
      end

      rule :comparison_tail do
        match('less', 'than', :aritm_expr) do |_, _, e|
          BoolNode.new(nil, '<', e); end
        match('greater', 'than', :aritm_expr) do  |_, _, e|
          BoolNode.new(nil, '>', e); end
        match(:aritm_expr, 'or', 'more') do |e, _, _|
          BoolNode.new(nil, '>=', e); end
        match(:aritm_expr, 'or', 'less') do |e, _, _|
          BoolNode.new(nil, '<=', e); end
        match('between', :aritm_expr, 'and', :aritm_expr) do |_, e, _, f|
          BoolNode.new(e, 'between', f, nil); end
        match(:aritm_expr) { |e| BoolNode.new(nil, '==', e) }
      end

      rule :aritm_expr do
        match(:aritm_expr, 'plus', :term) { |m, _, n| AritmNode.new(m, '+', n) }
        match(:aritm_expr, 'minus', :term) { |m, _, n| AritmNode.new(m, '-', n) }
        match(:term) { |m| m }
      end

      rule :term do
        match(:term, 'times', :factor) { |a, _, b| AritmNode.new(a, '*', b) }
        match(:term, 'divided', 'by', :factor) do |a, _, _, b|
          AritmNode.new(a, '/', b); end
        match(:factor) { |m| m }
      end

      rule :factor do
        match(:factor, 'modulo', :factor) { |a, _, b| AritmNode.new(a, '%', b) }
        match('(', :expression, ')') { |_, m, _| m }
        match(:number) { |m| m }
        match(:func_exec) { |m| m }
        match(:variable_get) { |m| m }
      end

      rule :func_decl do
        match(:identifier, 'with', :identifier_list, 'does', :newline,
              :indent, :statements, :dedent) do
          |name, _, params, _, _, _, stmts, _|
          FunctionDeclarationNode.new(name, stmts, params); end
        match(:identifier, 'does', :newline,
              :indent, :statements, :dedent) do |name, _, _, _, stmts, _|
          FunctionDeclarationNode.new(name, stmts); end
      end

      rule :func_exec do
        match('do', :identifier, 'with', :expression_list) do 
          |_, name, _, params|
          FunctionExecutionNode.new(name, params); end
        match('do', :identifier) { |_, name| FunctionExecutionNode.new(name) }
      end

      rule :identifier_list do
        match(:identifier_list, ',', :identifier) { |a, _, b| a << b }
        match(:identifier) { |m| [m] }
      end

      rule :number do
        match(Float) { |m| m }
        match(:integer) { |m| m }
      end

      rule :integer do
        match(Integer) { |m| m }
      end

      rule :identifier do
        match(/^[a-zA-Z]+$/) { |m| m }
      end

      rule :variable_get do
        match(:identifier) { |m| LookupNode.new(m) }
      end

      rule :string do
        match(/".*"/) { |m| m.to_s[1..-2] }
      end

      rule :array do
        match('[', :expression_list, ']') { |_, m, _| m }
        match('[', ']') { ArrayNode.new }
      end
    end
  end

  def parse(str)
    if $DEBUG_MODE
      @parser.parse(str)
    else
      begin
        @parser.parse(str)
      rescue => e
        $stderr.puts "#{e.class}: #{e}"
      end
    end
  end

  def prompt
    require 'readline'
    log(false)
    while input = Readline.readline(">> ", true)
      break if input == "exit"
      parse(input)
      puts
    end
  end

  def log(state = true)
    @parser.logger.level = state ? Logger::DEBUG : Logger::WARN
  end
end

if __FILE__ == $0
  pc = PseudoCode.new
  pc.log(false)

  # If no argument, parse either stdin-data or start a prompt
  if ARGV.empty?
    if $stdin.tty?
      pc.prompt
    else
      pc.parse $stdin.read
    end

    # Otherwise, try to parse file
  else
    parse_data = 
      begin
        File.read(ARGV[0])
      rescue SystemCallError => e
        $stderr.puts e
        exit 1
      end
    pc.parse(parse_data)
  end
end
