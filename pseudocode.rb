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

      start(:program) do
        match(:top_level_statements) { |a| ProgramNode.new(a, scope) }
      end

      # Statements only allowed in the global scope
      rule(:top_level_statements) do
        match(:top_level_statements, :func_decl) { |a, b| a << b }
        match(:top_level_statements, :statements) { |a, b| a + b }
        match(:empty) { [] }
      end

      # Statements allowed in any scope
      rule(:statements) do
        match(:newline, :statements) { |_, a| a }
        match(:statements, :newline, :statement) { |a, _, b| a << b }
        match(:statements, :newline) { |a, _| a }
        match(:statement) { |a| [a] }
      end

      rule(:statement) do
        match('write', :expression_list) { |_, a| WriteNode.new(a) }
        match('read', 'to', :identifier) { |_, _, a| InputNode.new(a) }
        match(:if)
        match(:while)
        match(:foreach)
        match('return', :expression) { |_, a| ReturnValue.new(a) }
        match(:assignment)
        match(:func_exec)
        match(:newline)
      end

      rule(:if) do
        match('if', :bool_expr, 'then', :newline,
              :indent, :statements, :dedent, :if_else) {
          |_, if_expr, _, _, _, if_stmts, _, elseif|
          ConditionNode.new(if_expr, if_stmts, elseif) }
      end

      rule(:if_else) do
        match(:newline, 'else', 'if', :bool_expr, 'then', :newline,
              :indent, :statements, :dedent, :if_else) {
          |_, _, _, if_expr, _, _, _, if_stmts, _, elseif|
          ConditionNode.new(if_expr, if_stmts, elseif) }
        match(:newline, 'else', :newline, :indent, :statements, :dedent) {
          |_, _, _, _, stmts, _| ConditionNode.new(true, stmts) }
        match(:empty)
      end

      rule(:while) do
        match('while', :bool_expr, 'do', :newline,
              :indent, :statements, :dedent) { |_, expr, _, _ , _, stmts, _|
          WhileNode.new(expr, stmts) }
      end

      rule(:foreach) do
        match('for', 'each', :identifier, :foreach_list, 'do', :newline,
              :indent, :statements, :dedent) {
          |_, _, var, iterator, _, _, _, stmts, _|
          ForEachNode.new(var, iterator, stmts) }
      end

      rule(:assignment) do
        match(:identifier, 'equals', :expression) { |lh, _, rh|
          AssignmentNode.new(lh, rh) }
        match(:assign_mod, :identifier, 'by', :expression) { |mod, lh, _, rh|
          AssignmentNode.new(lh, rh, mod) }
      end

      rule(:expression) do
        match(:func_exec)
        match(:bool_expr)
        match(:aritm_expr)
        match(:variable_get)
        match(:string)
        match(:array)
      end

      rule(:bool_expr) do
        match(:bool_expr, :and_or, :simple_bool) { |lh, sym, rh|
          BoolNode.new(lh, sym, rh) }
        match(:simple_bool)
      end

      rule(:simple_bool) do
        match('not', :bool_expr) { |sym, e| BoolNode.new(e, sym.to_sym) }
        match('true') { true }
        match('false') { false }
        match(:comparison)
      end

      rule(:comparison) do
        match(:aritm_expr, 'is', :comparison_tail) { |e, _, comp_node|
          comp_node.set_lh(e) }
        match(:aritm_expr)
      end

      rule(:comparison_tail) do
        match('less', 'than', :aritm_expr) do |_, _, e|
          BoolNode.new(nil, :<, e); end
        match('greater', 'than', :aritm_expr) do  |_, _, e|
          BoolNode.new(nil, :>, e); end
        match(:aritm_expr, 'or', 'more') do |e, _, _|
          BoolNode.new(nil, :>=, e); end
        match(:aritm_expr, 'or', 'less') do |e, _, _|
          BoolNode.new(nil, :<=, e); end
        match('between', :aritm_expr, 'and', :aritm_expr) do |_, e, _, f|
          BoolNode.new(e, 'between', f, nil); end
        match(:aritm_expr) { |e| BoolNode.new(nil, :==, e) }
      end

      rule(:aritm_expr) do
        match(:aritm_expr, :plus_minus, :term) { |lh, mod, rh|
          AritmNode.new(lh, mod, rh) }
        match(:term)
      end

      rule(:term) do
        match(:term, :mult_div, :factor) { |lh, mod, rh|
          AritmNode.new(lh, mod, rh) }
        match(:factor)
      end

      rule(:factor) do
        match(:factor, 'modulo', :factor) { |a, _, b| AritmNode.new(a, :%, b) }
        match('(', :expression, ')') { |_, m, _| m }
        match(:float)
        match(:integer)
        match(:func_exec)
        match(:variable_get)
      end

      rule(:func_decl) do
        match(:identifier, 'with', :identifier_list, 'does', :newline,
              :indent, :statements, :dedent) do
          |name, _, params, _, _, _, stmts, _|
          FunctionDeclarationNode.new(name, stmts, params); end
        match(:identifier, 'does', :newline,
              :indent, :statements, :dedent) do |name, _, _, _, stmts, _|
          FunctionDeclarationNode.new(name, stmts); end
      end

      rule(:func_exec) do
        match('do', :identifier, 'with', :expression_list) do 
          |_, name, _, params|
          FunctionExecutionNode.new(name, params); end
        match('do', :identifier) { |_, name| FunctionExecutionNode.new(name) }
      end

      # Lists
      rule(:identifier_list) do
        match(:identifier_list, ',', :identifier) { |a, _, b| a << b }
        match(:identifier) { |m| [m] }
      end

      rule(:expression_list) do
        match(:expression_list, ',', :expression) { |a, _, b| a << b }
        match(:expression) { |m| ArrayNode.new([m]) }
      end

      rule(:foreach_list) do
        match('in', :expression) { |_, iterator| iterator }
        match('from', :foreach_elem, 'to', :foreach_elem) { |_, start, _, stop|
          FromNode.new(start, stop) }
      end

      # Collections
      rule(:foreach_elem) do
        match(:variable_get)
        match(:integer)
      end

      rule(:assign_mod) do
        match('increase') { :+ }
        match('decrease') { :- }
        match('multiply') { :* }
        match('divide') { :/ }
      end

      rule(:and_or) do
        match('and') { :and }
        match('or')  { :or  }
      end

      rule(:plus_minus) do
        match('plus') { :+ }
        match('minus') { :- }
      end

      rule(:mult_div) do
        match('times') { :* }
        match('divided', 'by') { :/ }
      end

      # Types
      rule(:float)        { match(Float) }
      rule(:integer)      { match(Integer) }
      rule(:identifier)   { match(/^[a-zA-Z]+$/) }
      rule(:variable_get) { match(:identifier) { |m| LookupNode.new(m) } }
      rule(:string)       { match(/^".*"$/) { |m| m.delete('"') } }
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
