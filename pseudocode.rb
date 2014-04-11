# -*- coding: utf-8 -*-
require './rdparse.rb'
require './nodes.rb'

class PseudoCode
  def initialize
    @parser = Parser.new("pseudo parser") do
      token(/#.*?$/)
      token(/".*?"/)      { |m| m.to_s } # Strings
      token(/-?\d+\.\d+/) { |m| m.to_f } # Floats
      token(/-?\d+/)      { |m| m.to_i } # Integers
      token(/\w+/)        { |m| m } # Variables, keywords, etc
      token(/\n/)         { :newline } # Newline, this also causes the lexer to generate :indent and :dedent tokens
      token(/[^ ]/)       { |m| m } # Non-space characters
      token(/./)

      start :program do 
        match(:statements) { |statements| ProgramNode.new(statements).evaluate }
      end

      rule :statements do
        match(:statement, :newline, :statements) { |a, _, b| [a].flatten + b.flatten }
        match(:statement, :newline) { |a, _| [a].flatten }
        match(:newline, :statements) { |_, a| a.flatten}
        match(:statement) { |m| [m].flatten }
      end

      rule :statement do
        match(:output) { |m| m }
        match(:assignment) { |m| m }
        match(:input) { |m| m }
        match(:condition) { |m| m }
        match(:loop) { |m| m }
        match(:func_decl) { |m| m }
        match(:func_exec) { |m| m }
        match(:return_stmt) { |m| m }
        match(:newline) { [] }
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
        match('write', :expression) { |_, m| WriteNode.new(m) }
        match('write', :number) { |_, m| WriteNode.new(m) }
        match('write', :variable_get) { |_, m| WriteNode.new(m) }
        match('write', :string) { |_, m| WriteNode.new(m) }
      end

      rule :input do
        match('read', 'to', :variable_set) { |_, _, var_name| InputNode.new(var_name) }
      end
      
      rule :condition do
        match('if', :bool_expr, 'then', :newline, :indent, :statements, 
              :dedent, :newline, :condition_elseif) do |_, if_expr, _, _, _, if_stmts, _, _, elseif| 
          ConditionNode.new(if_expr, if_stmts, elseif); end
        match('if', :bool_expr, 'then', :newline, :indent, :statements, 
              :dedent, :newline, :condition_else) do |_, if_expr, _, _, _, if_stmts, _, _, else_| 
          ConditionNode.new(if_expr, if_stmts, else_); end
        match('if', :bool_expr, 'then', :newline, 
              :indent, :statements, :dedent) do |_, if_expr, _, _, _, if_stmts, _, _| 
          ConditionNode.new(if_expr, if_stmts); end
      end
     
      rule :condition_elseif do
        match('else', 'if', :bool_expr, 'then', :newline, :indent, :statements, 
              :dedent, :newline, :condition_elseif) do |_, _, if_expr, _, _, _, if_stmts, _, _, elseif| 
          ConditionNode.new(if_expr, if_stmts, elseif); end
        match('else', 'if', :bool_expr, 'then', :newline, :indent, :statements, 
              :dedent, :newline, :condition_else) do |_, _, if_expr, _, _, _, if_stmts, _, _, else_| 
          ConditionNode.new(if_expr, if_stmts, else_); end
        match('else', 'if', :bool_expr, 'then',
              :newline, :indent, :statements, :dedent) do |_, _, if_expr, _, _, _, if_stmts, _| 
          ConditionNode.new(if_expr, if_stmts); end
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
        match(:expression, ',', :expression_list) { |a, _, b| ArrayNode.new([a]) + b }
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
        match(:aritm_expr, 'is', 'less', 'than', :aritm_expr) do |e, _, _, _, f| 
          ComparisonNode.new(e,'<',f); end
        match(:aritm_expr, 'is', 'greater', 'than', :aritm_expr) do |e, _, _, _, f| 
          ComparisonNode.new(e, '>', f); end
        match(:aritm_expr, 'is', :aritm_expr, 'or', 'more') do |e, _, f, _, _| 
          ComparisonNode.new(e, '>=', f); end
        match(:aritm_expr, 'is', :aritm_expr, 'or', 'less') do |e, _, f, _, _| 
          ComparisonNode.new(e, '<=', f); end
        match(:aritm_expr, 'is', 'between', :aritm_expr, 'and', :aritm_expr) do |e, _, _, f, _, g| 
          ComparisonNode.new(f, 'between', g, e); end
        match(:aritm_expr, 'is', :aritm_expr) { |a, _, b| ComparisonNode.new(a, '==', b) }
        match(:aritm_expr) { |m| m }
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
        match(:identifier, ',', :parameters) { |a, _, b| [a] + b.flatten }
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

  def log(state = true)
    if state
      @parser.logger.level = Logger::DEBUG
    else
      @parser.logger.level = Logger::WARN
    end
  end
end

