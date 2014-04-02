# -*- coding: utf-8 -*-
require './rdparse.rb'
require './nodes.rb'

class PseudoCode
  def initialize
    @parser = Parser.new("pseudo parser") do
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
        match(:statement, :statements) { |a, b| [a] + b.flatten }
        match(:statement) { |m| [m] }
      end

      rule :statement do
        match(:output) { |m| m }
        match(:assignment) { |m| m }
#        match(:input) { |m| m }
#        match(:condition) { |m| m }
#        match(:loop) { |m| m }
#        match(:expression) { |m| m }
#        match(:func_decl) { |m| m }
#        match(:func_exec) { |m| m }
#        match(:return_stmt) { |m| m }
        match(:newline) { [] }
      end

     rule :assignment do
        match(:variable_set, 'equals', :expression) { |name, _, value| AssignmentNode.new(name, value) } 
        match('increase', :variable_set, 'by', :expression) { |_, name, _, value| AssignmentNode.new(name, value, '+=') } # +=
        match('decrease', :variable_set, 'by', :expression) {  |_, name, _, value| AssignmentNode.new(name, value, '-=') } # -=
        match('multiply', :variable_set, 'by', :expression) {  |_, name, _, value| AssignmentNode.new(name, value, '*=') } # *=
        match('divide', :variable_set, 'by', :expression) {  |_, name, _, value| AssignmentNode.new(name, value, '/=') } # /=
        match(:variable_set, 'holds', :expression_list) { |name, _, value| AssignmentNode.new(name, value, 'array') } # Work in progress
     end

      rule :output do
        match('write', :expression) { |_, m| WriteNode.new(m) }
        match('write', :number) { |_, m| WriteNode.new(m) }
        match('write', :variable_get) { |_, m| WriteNode.new(m) }
        match('write', :string) { |_, m| WriteNode.new(m) }
      end

#     rule :input do
#       match('read', 'to', :variable_set)
#     end

#     rule :condition do
#        match('if', :bool_expr, 'then', '\n', '\t', :statements, DEDENT, :condition_elseif, :condition_else) # work in progress
#     end
      
#     rule :condition_elseif do
#        match('else if', :bool_expr, 'then', '\n', '\t', :statements, DEDENT, :condition_elseif) # work in progress
#       match(:empty)
#     end

#     rule :condition_else do
#        match('else', '\n', '\t', :statements, DEDENT) # work in progress
#       match(:empty)
#     end

#     rule :loop do
#       match(:foreach)
#       match(:while)
#     end

#     rule :foreach do
#        match('for', 'each', :variable_set, 'in', :variable_get, 'do', '\n', '\t', :statements, DEDENT)
#        match('for', 'each', :variable_set, :from, 'do', '\n', '\t', :statements, DEDENT)
#     end

#     rule :while do
#        match('while', :bool_expr, 'do', '\n', '\t', :statements, DEDENT)
#     end

#     rule :from do
#       match('from', :variable_get, 'to', :variable_get)
#       match('from', :variable_get, 'to', :integer)
#       match('from', :integer, 'to', :variable_get)
#       match('from', :integer, 'to', :integer)
#     end

      rule :expression do
        match(:bool_expr) { |m| m }
        match(:aritm_expr) { |m| m }
        match(:variable_get) { |m| m }
#       match(:func_exec)
      end

      rule :expression_list do
        match(:expression, ',', :expression_list) { |a, _, b| [a] + b }
        match(:expression) { |m| [m] }
      end

      rule :bool_expr do
        # Tar ej bool?
        match(:aritm_expr, 'is', 'less', 'than', :aritm_expr) { |e, _, _, _, f| ComparisonNode.new(e,'<',f) }
        match(:aritm_expr, 'is', 'greater', 'than', :aritm_expr) { |e, _, _, _, f| ComparisonNode.new(e, '>', f) }
        match(:aritm_expr, 'is', :aritm_expr, 'or', 'more') { |e, _, f, _, _| ComparisonNode.new(e, '>=', f) }
        match(:aritm_expr, 'is', :aritm_expr, 'or', 'less') { |e, _, f, _, _| ComparisonNode.new(e, '<=', f) }
        match(:aritm_expr, 'is', 'between', :aritm_expr, 'and', :aritm_expr) { |e, _, _, f, _, g| ComparisonNode.new(f, 'between', g, e) }
        # Tar ej arithm?
        match(:bool_expr, 'and', :bool_expr) { |e, _, f| BoolAndNode.new(e,f) }
        match(:bool_expr, 'or', :bool_expr) { |e, _, f| BoolOrNode.new(e,f) }
        match('not', :bool_expr) { |_, e| BoolNotNode.new(e) }
        match('(', :bool_expr, ')') { |_, e, _| BoolNode.new(e) }
        match(:bool) { |m| BoolNode.new(m) }
      end

      rule :aritm_expr do
        match(:term, 'plus', :aritm_expr) { |m, _, n| ArithmNode.new(m, '+', n) }
        match(:term, 'minus', :aritm_expr) { |m, _, n| ArithmNode.new(m, '-', n) }
        match(:term) { |m| m }
      end

      rule :term do
        match(:factor, 'modulo', :term) { |a, _, b| ArithmNode.new(a, '%', b) }
        match(:factor, 'times', :term) { |a, _, b| ArithmNode.new(a, '*', b) }
        match(:factor, 'divided', 'by', :term) { |a, _, _, b| ArithmNode.new(a, '/', b) }
        match(:factor) { |m| m }
      end

      rule :factor do
        match('(', :aritm_expr, ')') { |_, m, _| m }
        match(:number) { |m| m}
        match(:variable_get) { |m| m }
      end

#     rule :func_decl do
#        match(:func_name, :parameters, 'does', '\n', '\t', :statements, DEDENT) # work in progress
#     end
      
#     rule :func_exec do
#       match('do', :func_name, :parameters)
#     end

#     rule :parameters do
#       match('with', :variable_list)
#       match(:empty)
#     end

#     rule :variable_list do
#       match(:variable_get)
#       match(:variable_get, ',', :variable_list)
#     end

#     rule :return_stmt do
#       match('return', :expression, '\n') { |_, m, _| m }
#     end

      rule :number do
        match(Float) { |m| m}
        match(Integer) { |m| m}
      end

      rule :variable do
        match(/^[a-zA-Z]+$/) { |m| m }
      end

      rule :variable_get do
        match(:variable) { |m| LookupNode.new(m) }
      end

      rule :variable_set do
        match(:variable) { |m| m }
      end

      rule :bool do
        match('false') { false }
        match('true') { true }
      end

      rule :string do
        match(/".*"/) { |m| m.to_s[1..-2] }
      end

      rule :comment do
        match(/^#.*?$/)
      end

      rule :empty do
        match(/^$/)
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

