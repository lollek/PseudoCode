# Ruby Classes
class Object
  def evaluate(scope)
    self
  end

  def evaluate_all(scope)
    self
  end
end

# Custom Classes
class PseudoCodeError < RuntimeError; end

class SuperNode
  def initialize_global_variables(scope)
    @@global_scope = scope
  end

  def evaluate_all(scope)
    evaluate(scope).evaluate_all(scope)
  end
end

class ProgramNode < SuperNode
  def initialize(statements, scope)
    @statements = statements
    initialize_global_variables(scope)
    evaluate
  end

  private
  def evaluate
    @statements.each do |s|
      if (s = s.evaluate(@@global_scope)).class == ReturnValue
        return s.value.class == Fixnum ? s.value : 0
      end
    end
    0
  end
end

class Scope
  attr_reader :variables
  def initialize(parent=nil)
    @parent = parent
    @variables = {}
    @functions = {}
  end

  def set_var(name, value)
    if @parent and @parent.get_var(name)
      @parent.set_var(name, value)
    else
      @variables[name] = value
    end
  end

  def get_var(name)
    if @variables.include?(name) 
      @variables[name]
    elsif @parent 
      @parent.get_var(name)
    else 
      nil
    end
  end

  def set_func(name, node)
    @functions[name] = node
  end

  def get_func(name)
    if @functions.include?(name)
      @functions[name]
    elsif @parent
      @parent.get_func(name)
    else
      nil
    end
  end
end

class AssignmentNode < SuperNode
  def initialize(name, value, op=nil)
    @name, @value, @op = name, value, op
  end

  def evaluate(scope)
    value = @value.evaluate_all(scope)
    case @op
    when nil then scope.set_var(@name, value)
    when '+=' then scope.set_var(@name, scope.get_var(@name) + value)
    when '-=' then scope.set_var(@name, scope.get_var(@name) - value)
    when '*=' then scope.set_var(@name, scope.get_var(@name) * value)
    when '/=' then scope.set_var(@name, scope.get_var(@name) / value)
    when 'array' then scope.set_var(@name, value)
    end
  end
end

class InputNode < SuperNode
  def initialize(var_name)
    @name = var_name
  end

  def evaluate(scope)
    input = gets
    input.chomp! if input
    AssignmentNode.new(@name, input).evaluate(scope)
  end
end

class ConditionNode < SuperNode
  def initialize(expr, stmts, elseif=nil)
    @expression, @statements, @elseif = expr, stmts, elseif
  end

  def evaluate(parent_scope)
    scope = Scope.new(parent_scope)
    if @expression.evaluate(scope)
      @statements.each do |s| 
        if (s = s.evaluate(scope)).class == ReturnValue
          return s
        end
      end
    elsif @elseif != nil
      if (s = @elseif.evaluate(scope)).class == ReturnValue
        return s
      end
    end
    nil
  end
end

class WhileNode < SuperNode
  def initialize(expr, stmts)
    @expression, @statements = expr, stmts
  end

  def evaluate(parent_scope)
    scope = Scope.new(parent_scope)
    while @expression.evaluate(scope)
      @statements.each do |s| 
        if (s = s.evaluate(scope)).class == ReturnValue
          return s
        end
      end
    end
    nil
  end
end

class ForEachNode < SuperNode
  def initialize(var, it, stmts)
    @var, @iterator, @statements = var, it, stmts
  end

  def evaluate(parent_scope)
    scope = Scope.new(parent_scope)
    case (iterator = @iterator.evaluate(scope))
    when ArrayNode then iterator
    when Array then iterator
    when String then iterator.each_char
    else raise "Bad iterator class (#{iterator.class}) received!"
    end.each do |elem|
      AssignmentNode.new(@var, elem).evaluate(scope)
      @statements.each do |s|
        if (s = s.evaluate(scope)).class == ReturnValue
          return s
        end
      end
    end
    nil
  end
end

class FromNode < SuperNode
  def initialize(start, stop)
    @start, @stop = start, stop
  end

  def evaluate(scope)
    if (stop = @stop.evaluate(scope)) > (start = @start.evaluate(scope))
      ArrayNode.new((start..stop).to_a)
    else
      ArrayNode.new(start.downto(stop).to_a)
    end
  end
end

class LookupNode < SuperNode
  def initialize(name)
    @name = name
  end

  def evaluate(scope)
    if (results = scope.get_var(@name)).nil?
      p scope if $DEBUG_MODE
      raise PseudoCodeError, "Variable '#{@name}' does not exist!"
    end
    results
  end
end

class ExpressionNode < SuperNode
  def initialize(value)
    @value = value
  end
  def evaluate(scope)
    @value.evaluate(scope)
  end
end

class BoolNode < SuperNode
  def initialize(value)
    @value = value
  end
  def evaluate(scope)
    @value.evaluate(scope)
  end
end

class BoolOrNode < SuperNode
  def initialize(lh, rh)
    @lh, @rh = lh, rh
  end
  def evaluate(scope)
    @lh.evaluate(scope) || @rh.evaluate(scope)
  end
end

class BoolAndNode < SuperNode
  def initialize(lh, rh)
    @lh, @rh = lh, rh
  end
  def evaluate(scope)
    @lh.evaluate(scope) && @rh.evaluate(scope)
  end
end

class BoolNotNode < SuperNode
  def initialize(value)
    @value = value
  end
  def evaluate(scope)
    @value.evaluate(scope) == false
  end
end

class WriteNode < SuperNode
  def initialize(value)
    @value = value
  end

  def evaluate(scope)
    if $DEBUG_MODE
      File.open("f", "a") { |f| @value.each { |a| f.print(a.evaluate_all(scope)) } }
    else
      @value.each { |a| print(unescape(a.evaluate_all(scope))) }
    end
    nil
  end

  def unescape(s)
    eval %Q{"#{s}"}
  end
  
end

class ComparisonNode < SuperNode
  def initialize(lh, op, rh, middle=nil)
    @lh, @op, @rh, @middle = lh, op, rh, middle
  end
  def evaluate(scope)
    lh = @lh.evaluate(scope)
    rh = @rh.evaluate(scope)
    middle = @middle.evaluate(scope) unless @middle.nil?
    case @op
    when '<' then lh < rh
    when '>' then lh > rh
    when '<=' then lh <= rh
    when '>=' then lh >= rh
    when 'between' then middle.between?([lh,rh].min, [lh, rh].max)
    when '==' then lh == rh
    end
  end

  def set_lh(value)
    if @op == 'between'
      @middle = value
    else
      @lh = value
    end
    self
  end
end

class AritmNode < SuperNode
  def initialize(lh, op, rh)
    @lh, @op, @rh = lh, op, rh
  end
  def evaluate(scope)
    lh = @lh.evaluate(scope)
    rh = @rh.evaluate(scope)
    case @op
    when '+' then lh + rh
    when '-' then lh - rh
    when '%' then lh % rh
    when '*' then lh * rh
    when '/' then lh / rh
    end
  end
end

class ArrayNode < SuperNode
  attr_reader :values
  def initialize(values=[])
    @values = values
  end
  
  def evaluate(scope)
    @values
  end

  def evaluate_all(scope)
    @values.map { |z| z.evaluate_all(scope) }
  end

  def +(array)
    ArrayNode.new(@values + array.values)
  end

  def each
    @values.each { |e| yield(e) }
  end
end

class FunctionDeclarationNode < SuperNode
  def initialize(name, stmts, params=[])
    @name, @parameters, @statements = name, params, stmts
  end

  def evaluate(scope)
    @@global_scope.set_func(@name, FunctionNode.new(@parameters, @statements))
    nil
  end
end

class FunctionExecutionNode < SuperNode
  def initialize(name, params=ArrayNode.new([]))
    @name, @parameters = name, params
  end

  def evaluate(scope)
    @@global_scope.get_func(@name).evaluate(scope, @parameters.evaluate_all(scope))
  end
end

class FunctionNode < SuperNode
  def initialize(params, stmts)
    @param_names, @statements = params, stmts
  end

  def evaluate(parent_scope, param_values=[])
    raise PseudoCodeError, "Parameter mismatch! Expected #{@param_names.length}, found #{param_values.length}" unless @param_names.length == param_values.length
    scope = Scope.new#(parent_scope)
    @param_names.each_index do |i| 
      AssignmentNode.new(@param_names[i], param_values[i]).evaluate(scope)
    end
    @statements.each do |s| 
      if s.class == ReturnValue
        return s.evaluate(scope).value
      else
        return_value = s.evaluate(scope)
        return return_value.value if return_value.class == ReturnValue
      end
    end
    nil
  end
end

class ReturnValue
  attr_reader :value
  def initialize(value)
    @value = value
  end

  def evaluate(scope)
    @value = @value.evaluate_all(scope)
    self
  end
end
