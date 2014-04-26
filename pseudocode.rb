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
        match(:top_level_statements) { |statements| ProgramNode.new(statements, scope).evaluate }
      end

      rule :top_level_statements do
        match(:top_level_statements, :func_decl)  { |m, n| m.flatten + [n].flatten }
        match(:top_level_statements, :statements) { |m, n| m.flatten + [n].flatten }
        match(:func_decl) { |m| [m].flatten }
        match(:statements) { |m| [m].flatten }
      end

      rule :statements do
        match(:newline, :statements) { |_, a| a.flatten }
        match(:statements, :newline, :statement) { |a, _, b| a.flatten + [b].flatten }
        match(:statements, :newline) { |a, _| [a].flatten }
        match(:statement) { |m| [m].flatten }
      end

      rule :statement do
        match(:output) { |m| m }
        match(:assignment) { |m| m }
        match(:input) { |m| m }
        match(:condition) { |m| m }
        match(:loop) { |m| m }
        match(:func_exec) { |m| m }
        match(:return_stmt) { |m| m }
        match(:newline)
      end

     rule :assignment do
        match(:variable_set, 'equals', :expression) do |name, _, value| 
          AssignmentNode.new(name, value); end
        match('increase', :variable_set, 'by', :expression) do |_, name, _, value|
          AssignmentNode.new(name, value, '+='); end # +=
        match('decrease', :variable_set, 'by', :expression) do |_, name, _, value|
          AssignmentNode.new(name, value, '-='); end # -=
        match('multiply', :variable_set, 'by', :expression) do |_, name, _, value|
          AssignmentNode.new(name, value, '*='); end # *=
        match('divide', :variable_set, 'by', :expression) do |_, name, _, value|
          AssignmentNode.new(name, value, '/='); end # /=
      end

      rule :output do
        match('write', :write_list) { |_, m| WriteNode.new(m) }
      end

      rule :write_list do
        match(:write_list, ',', :expression) { |a, _, b| a.flatten + [b] }
        match(:expression) { |m| [m] }
      end

      rule :input do
        match('read', 'to', :variable_set) { |_, _, var_name| InputNode.new(var_name) }
      end

      rule :condition do
        match('if', :bool_expr, 'then', :newline, :indent, :statements, :condition_tail) do 
          |_, if_expr, _, _, _, if_stmts, elseif| ConditionNode.new(if_expr, if_stmts, elseif); end
      end

      rule :condition_tail do
        match(:dedent, :newline, :condition_elseif) { |_, _, elseif| elseif }
        match(:dedent, :newline, :condition_else) { |_, _, else_| else_ }
        match(:dedent)
      end

      rule :condition_elseif do
        match('else', 'if', :bool_expr, 'then', :newline, :indent, :statements, :condition_elseif_tail) do
          |_, _, if_expr, _, _, _, if_stmts, elseif| ConditionNode.new(if_expr, if_stmts, elseif); end
      end

      rule :condition_elseif_tail do
        match(:dedent, :newline, :condition_elseif) { |_, _, elseif| elseif }
        match(:dedent, :newline, :condition_else) { | _, _, else_| else_ }
        match(:dedent)
      end

      rule :condition_else do
        match('else', :newline, :indent, :statements, :dedent) do
          |_, _, _, stmts, _| ConditionNode.new(true, stmts); end
      end

      rule :loop do
        match(:foreach) { |m| m }
        match(:while) { |m| m }
      end

      rule :foreach do
        match('for', 'each', :identifier, 'in', :expression, 'do',
              :newline, :indent, :statements, :dedent) do |_, _, var, _, iterator, _, _, _, stmts, _| 
          ForEachNode.new(var, iterator, stmts); end
        match('for', 'each', :identifier, :from, 'do', :newline, 
              :indent, :statements, :dedent) do |_, _, var, iterator, _, _, _, stmts, _| 
          ForEachNode.new(var, iterator, stmts); end
      end

      rule :while do
        match('while', :bool_expr, 'do', :newline, 
              :indent, :statements, :dedent) do |_, expr, _, _ , _, stmts, _|
          WhileNode.new(expr, stmts); end
      end

      rule :from do
        match('from', :variable_get, 'to', :variable_get) { |_, start, _, stop| FromNode.new(start, stop) }
        match('from', :variable_get, 'to', :integer) { |_, start, _, stop| FromNode.new(start, stop) }
        match('from', :integer, 'to', :variable_get) { |_, start, _, stop| FromNode.new(start, stop) }
        match('from', :integer, 'to', :integer) { |_, start, _, stop| FromNode.new(start, stop) }
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
        match(:expression_list, ',', :expression) { |a, _, b| a + ArrayNode.new([b]) }
        match(:expression) { |m| ArrayNode.new([m]) }
      end

      rule :bool_expr do
        match(:bool_expr, 'and', :simple_bool) { |e, _, f| BoolAndNode.new(e,f) }
        match(:bool_expr, 'or', :simple_bool) { |e, _, f| BoolOrNode.new(e,f) }
        match(:simple_bool) { |m| m }
      end

      rule :simple_bool do
        match('not', :bool_expr) { |_, e| BoolNotNode.new(e) }
        match(:bool) { |m| BoolNode.new(m) }
        match(:comparison) { |m| m }
      end

      rule :comparison do
        match(:aritm_expr, 'is', :comparison_tail) { |e, _, comp_node| comp_node.set_lh(e) }
        match(:aritm_expr) { |m| m }
      end

      rule :comparison_tail do
        match('less', 'than', :aritm_expr) { |_, _, e| ComparisonNode.new(nil, '<', e) }
        match('greater', 'than', :aritm_expr) { |_, _, e| ComparisonNode.new(nil, '>', e) }
        match(:aritm_expr, 'or', 'more') { |e, _, _| ComparisonNode.new(nil, '>=', e) }
        match(:aritm_expr, 'or', 'less') { |e, _, _| ComparisonNode.new(nil, '<=', e) }
        match('between', :aritm_expr, 'and', :aritm_expr) do |_, e, _, f| 
          ComparisonNode.new(e, 'between', f, nil); end
        match(:aritm_expr) { |e| ComparisonNode.new(nil, '==', e) }
      end

      rule :aritm_expr do
        match(:term, 'plus', :aritm_expr) { |m, _, n| AritmNode.new(m, '+', n) }
        match(:term, 'minus', :aritm_expr) { |m, _, n| AritmNode.new(m, '-', n) }
        match(:term) { |m| m }
      end

      rule :term do
        match(:factor, 'modulo', :term) { |a, _, b| AritmNode.new(a, '%', b) }
        match(:factor, 'times', :term) { |a, _, b| AritmNode.new(a, '*', b) }
        match(:factor, 'divided', 'by', :term) { |a, _, _, b| AritmNode.new(a, '/', b) }
        match(:factor) { |m| m }
      end

      rule :factor do
        match('(', :expression, ')') do
          |_, m, _| ExpressionNode.new(m)
        end
        match(:number) { |m| m}
        match(:func_exec) { |m| m }
        match(:variable_get) { |m| m }
      end

      rule :func_decl do
        match(:identifier, 'with', :parameters, 'does', 
              :newline, :indent, :statements, :dedent) do |name, _, params, _, _, _, stmts, _|
          FunctionDeclarationNode.new(name, stmts, params); end
        match(:identifier, 'does', :newline, 
              :indent, :statements, :dedent) do |name, _, _, _, stmts, _|
          FunctionDeclarationNode.new(name, stmts); end
      end

      rule :func_exec do
        match('do', :identifier, 'with', :expression_list) do |_, name, _, params| 
          FunctionExecutionNode.new(name, params); end
        match('do', :identifier) do |_, name| FunctionExecutionNode.new(name)
        end
      end

      rule :parameters do
        match(:parameters, ',', :identifier) { |a, _, b| a.flatten + [b] }
        match(:identifier) { |m| [m] }
      end

      rule :return_stmt do
        match('return', :expression) { |_, m| ReturnValue.new(m) }
      end

      rule :number do
        match(:float) { |m| m }
        match(:integer) { |m| m }
      end

      rule :integer do
        match(Integer) { |m| m }
      end

      rule :float do
        match(Float) { |m| m }
      end

      rule :identifier do
        match(/^[a-zA-Z]+$/) { |m| m }
      end

      rule :variable_get do
        match(:identifier) { |m| LookupNode.new(m) }
      end

      rule :variable_set do
        match(:identifier) { |m| m }
      end

      rule :bool do
        match('false') { false }
        match('true') { true }
      end

      rule :string do
        match(/".*"/) { |m| m.to_s[1..-2] }
      end

      rule :array do
        match('[', :expression_list, ']') { |_, m, _| m }
        match('[', ']') { ArrayNode.new() }
      end
    end
  end

  def parse(str)
    @parser.parse(str)
  end

  def prompt
    require 'readline'
    pc = PseudoCode.new()
    pc.log(false)
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
  pc = PseudoCode.new()
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
        filename = File.read(ARGV[0])
      rescue SystemCallError => e
        $stderr.puts e
        exit 1
      end
    pc.parse(parse_data)
  end
end
