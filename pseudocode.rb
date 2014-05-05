#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

import_path =
  if File.symlink?(__FILE__)
    File.dirname(File.absolute_path(File.readlink(__FILE__)))
  else
    File.dirname(File.absolute_path(__FILE__))
  end

require "#{import_path}/rdparse.rb"
require "#{import_path}/nodes.rb"

class PseudoCode
  def initialize(scope=Scope.new)
    @parser = Parser.new("pseudo parser") do
      token(/#.*?$/)             # Comments
      token(/".*?"/)             { |m| m.to_s } # Strings
      token(/(-?\d+)*[a-zA-Z]+/) { |m| m }      # Variables, keywords, etc
      token(/-?\d+\.\d+/)        { |m| m.to_f } # Floats
      token(/-?\d+/)             { |m| m.to_i } # Integers
      token(/\n+/)               # :newline, :indent and :dedent tokens
      token(/[^ ]/)              { |m| m } # Non-space characters
      token(/ /)                 # Throw away spaces

      start(:program) do
        match(:top_level_statements) { |a| ProgramNode.new(a, scope).evaluate }
      end

      # Statements only allowed in the global scope
      rule(:top_level_statements) do
        match(:prompt, :expression, :newline) { |_, a, _| [a] }
        match(:top_level_statements, :func_decl) { |a, b| a << b }
        match(:top_level_statements, :statements) { |a, b| a + b }
        match(:empty) { [] }
        #match(:prompt, :newline) { nil }
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
        match(:condition)
        match(:while)
        match(:foreach)
        match('return', :expression) { |_, a| ReturnValue.new(a) }
        match(:assignment)
        match(:func_exec)
        match(:newline)
      end

      rule(:condition) do
        match('if', :expression, 'then', :newline,
              :indent, :statements, :dedent, :condition_else) {
          |_, if_expr, _, _, _, if_stmts, _, elseif|
          ConditionNode.new(if_expr, if_stmts, elseif) }
      end

      rule(:condition_else) do
        match(:newline, 'else', 'if', :expression, 'then', :newline,
              :indent, :statements, :dedent, :condition_else) {
          |_, _, _, if_expr, _, _, _, if_stmts, _, elseif|
          ConditionNode.new(if_expr, if_stmts, elseif) }
        match(:newline, 'else', :newline, :indent, :statements, :dedent) {
          |_, _, _, _, stmts, _| ConditionNode.new(true, stmts) }
        match(:empty)
      end

      rule(:while) do
        match('while', :expression, 'do', :newline,
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
        match(:expression, :and_or, :expression) { |lh, sym, rh|
          ComparisonNode.new(lh, sym, rh) }
        match('not', :expression) { |sym, e| ComparisonNode.new(e, sym.to_sym) }
        match(:bool)
        match(:comparison)
      end

      rule(:comparison) do
        match(:comparable, 'is', :comparison_tail) { |e, _, comp_node|
          comp_node.set_lh(e) }
        match(:aritm_expr)
      end
      
      rule(:comparison_tail) do
        match('less', 'than', :comparable) do |_, _, e|
          ComparisonNode.new(nil, :<, e); end
        match('greater', 'than', :comparable) do  |_, _, e|
          ComparisonNode.new(nil, :>, e); end
        match(:comparable, 'or', 'more') do |e, _, _|
          ComparisonNode.new(nil, :>=, e); end
        match(:comparable, 'or', 'less') do |e, _, _|
          ComparisonNode.new(nil, :<=, e); end
        match('between', :comparable, 'and', :comparable) do |_, e, _, f|
          ComparisonNode.new(e, :between, f, nil); end
        match(:comparable) { |e| ComparisonNode.new(nil, :==, e) }
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
        match(:index, 'of', :indexable) { |index, _, list| IndexNode.new(list, index) }
        match(:variable_get)
        match(:string)
        match(:array)
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

      rule(:comparable) do
        match(:aritm_expr)
        match(:string)
        match(:array)
      end

      rule(:index) do
        match(/^\d*(11|12|13)th$/)
        match(/^\d*1st$/)
        match(/^\d*2nd$/)
        match(/^\d*3rd$/)
        match(/^\d+th$/)
        match(/^[a-zA-Z]+th$/) { |m| LookupNode.new(m[0...-2]) }
        match('last')
      end

      rule(:indexable) do
        match(:string)
        match(:array)
        match(:variable_get)
      end
        
      # Types
      rule(:float)        { match(Float) }
      rule(:integer)      { match(Integer) }
      rule(:identifier)   { match(/^[a-zA-Z]+$/) }
      rule(:variable_get) { match(:identifier) { |m| LookupNode.new(m) } }
      rule(:string)       { match(/".*"/) { |m| m.delete('"') } }
      rule :array do
        match('[', :expression_list, ']') { |_, m, _| m }
        match('[', ']') { ArrayNode.new }
      end
      rule(:bool) do
        match('true') { true }
        match('false') { false }
      end
    end
  end

  def parse(str, interactive=false)
    str = str + "\n"
    if $DEBUG_MODE
      @parser.parse(str, interactive)
    else
      begin
        @parser.parse(str, interactive)
      rescue Parser::ParseError => e
        $stderr.puts "SyntaxError: #{e}"
      rescue => e
        $stderr.puts "#{e.class}: #{e}"
      end
    end
  end

  def prompt
    require 'readline'
    log(false)
    begin
      while input = Readline.readline(">> ", true)
        break if input == "exit"
        puts parse(input, true)
      end
    rescue Interrupt
      puts
      exit
    end
  end

  def log(state = true)
    @parser.logger.level = state ? Logger::DEBUG : Logger::WARN
    # @parser.logger.level = Logger::DEBUG
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
