# -*- coding: utf-8 -*-
require './rdparse.rb'

class PseudoCode
  def initialize
    @parser = Parser.new("pseudo parser") do
      token(/\w+/) {|m| m } # w kanske matchar för mycket..
      token(/\d+\.\d+/) {|m| m.to_f }
      token(/\d+/) {|m| m.to_i }
      token(/./) {|m| m }
      
      start :program do 
        match(:statements) { |statements| ProgramNode.new(statements) }
      end
      
      rule :statements do 
        match(:statements, :statement) { |a, b| b + a }
        match(:empty) { [] }
      end

      rule :statement do
        match(:assignment, '\n') { |m| m }
        match(:output, '\n') { |m| m }
        match(:input, '\n') { |m| m }
        match(:condition, '\n') { |m| m }
        match(:loop, '\n') { |m| m }
        match(:expression, '\n') { |m| m }
        match(:func_decl, '\n') { |m| m }
        match(:func_exec, '\n') { |m| m }
        match(:return_stmt, '\n') { |m| m }
      end

      rule :assignment do
        match(:variable_set, 'equals', :expression) { |var, _, val| @variables[var] = val } 
        match('increase', :variable_set, 'by', :expression) { |_, var, _, val| @variables[var] += val } # +=
        match('decrease', :variable_set, 'by', :expression) { |_, var, _, val| @variables[var] -= val } # -=
        match('multiply', :variable_set, 'by', :expression) { |_, var, _, val| @variables[var] *= val } # *=
        match('divide', :variable_set, 'by', :expression) { |_, var, _, val| @variables[var] /= val } # /=
        match(:variable_set, 'holds', '\n', '\t', :expression_list, DEDENT) { |var, _, _, _, val| @variables[var] = val } # Work in progress
      end

      rule :output do
        match('write', :variable_get) { |_, m| print(m) }
        match('write', :expression) { |_, m| print(m) }
        match('write', :string) { |_, m| print(m) }
        match('write', :number) { |_, m| print(m) }
      end

      rule :input do
        match('read', 'to', :variable_set)
      end

      rule :condition do
        match('if', :bool_expr, 'then', '\n', '\t', :statements, DEDENT, :condition_elseif, :condition_else) # work in progress
      end
      
      rule :condition_elseif do
        match('else if', :bool_expr, 'then', '\n', '\t', :statements, DEDENT, :condition_elseif) # work in progress
        match(:empty)
      end

      rule :condition_else do
        match('else', '\n', '\t', :statements, DEDENT) # work in progress
        match(:empty)
      end

      rule :loop do
        match(:foreach)
        match(:while)
      end

      rule :foreach do
        match('for', 'each', :variable_set, 'in', :variable_get, 'do', '\n', '\t', :statements, DEDENT)
        match('for', 'each', :variable_set, :from, 'do', '\n', '\t', :statements, DEDENT)
      end

      rule :while do
        match('while', :bool_expr, 'do', '\n', '\t', :statements, DEDENT)
      end

      rule :from do
        match('from', :variable_get, 'to', :variable_get)
        match('from', :variable_get, 'to', :integer)
        match('from', :integer, 'to', :variable_get)
        match('from', :integer, 'to', :integer)
      end

      rule :expression do
        match(:bool_expr)
        match(:aritm_expr)
        match(:func_exec)
      end

      rule :expression_list do
        match(:expression, '\n', :expression_list)
        match(:empty)
      end

      rule :bool_expr do
        match(:expression, 'is', 'less', 'than', :expression)
        match(:expression, 'is', 'greater', 'than', :expression)
        match(:expression, 'is', :expression, 'or', 'more')
        match(:expression, 'is', :expression, 'or', 'less')
        match(:expression, 'is', 'between', :expression, 'and', :expression)
        match(:expression, 'and', :expression)
        match(:expression, 'or', :expression)
        match('(', :expression, ')')
        match(:expression)
        match(:bool)
      end

      rule :aritm_expr do
        match(:term, 'plus', :expression)
        match(:term, 'minus', :expression)
        match(:term)
      end

      rule :term do
        match(:factor) { |m| m }
        match(:factor, 'times', :factor) { |a, _, b| a * b }
        match(:factor, 'divided', 'by', :factor) { |a, _, _, b| a / b }
        match(:factor, 'modulo', :factor) { |a, _, b| a % b }
      end

      rule :factor do
        match(:number) { |m| m}
        match(:variable_get) { |m| m}
        match('(', :term, ')')
      end

      rule :func_decl do
        match(:func_name, :parameters, 'does', '\n', '\t', :statements, DEDENT) # work in progress
      end
      
      rule :func_exec do
        match('do', :func_name, :parameters)
      end

      rule :parameters do
        match('with', :variable_list)
        match(:empty)
      end

      rule :variable_list do
        match(:variable_get)
        match(:variable_get, ',', :variable_list)
      end

      rule :return_stmt do
        match('return', :expression, '\n') { |_, m, _| m }
      end

      rule :number do
        match(:float) { |m| m}
        match(:integer) { |m| m}
      end
      
      rule :integer do
        match(/\d+/) { |m| m.to_i }
      end
      
      rule :float do
        match(/\d+\.\d+/) { |m| m.to_f }
      end

      rule :variable do
        match(/[a-zA-Z]+/) { |m| m }
      end

      rule :variable_get do
        match(:variable) { |m| @variables[m] }
      end

      rule :variable_set do
        match(:variable) { |m| m }
      end

      rule :bool do
        match('true') { true }
        match('false')  { false }
      end

      rule :string do
        match('"', /.*?/, '"') { |m| m.to_s }
      end

      rule :comment do
        match(/#.*?$/)
      end

      rule :emtpy do
        match(//)
      end
    end
  end
end

class ProgramNode
  def initialize(statements)
    @statements = statements
  end

  def evaluate
    @statements.each { |s| s.evaluate }
  end
end
