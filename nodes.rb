class SuperNode
  def initialize_global_variables
    @@variables = Scope.new
  end
end

class ProgramNode < SuperNode
  def initialize(statements)
    @statements = statements
    initialize_global_variables
  end

  def evaluate
    @statements.each { |s| s.evaluate(@@variables) }
    nil
  end
end

class StatementNode < SuperNode
  def initialize(statements)
    @statements = statements
  end

  def evaluate(scope)
    @statements.each { |s| s.evaluate(scope) }
    nil
  end
end

class Scope
  def initialize(parent=nil)
    @parent = parent
    @variables = {}
  end

  def set(name, value)
    if @parent and @parent.get(name)
      @parent.set(name, value)
    else
      @variables[name] = value
    end
  end
  
  def get(name)
    if @variables.include?(name)
      @variables[name]
    elsif @parent
      @parent.get(name)
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
    value = @value.class.superclass == SuperNode ? @value.evaluate(scope) : @value
    case @op
    when nil then scope.set(@name, value) # =
    when '+=' then scope.set(@name, scope.get(@name) + value)
    when '-=' then scope.set(@name, scope.get(@name) - value)
    when '*=' then scope.set(@name, scope.get(@name) * value)
    when '/=' then scope.set(@name, scope.get(@name) / value)
    when 'array' then scope.set(@name, value)
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
    expression = @expression.class.superclass == SuperNode ? @expression.evaluate(scope) : @expression
    if expression
      @statements.each { |s| s.evaluate(scope) }
    elsif @elseif != nil
      @elseif.evaluate(scope)
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
    while @expression.class.superclass == SuperNode ? @expression.evaluate(scope) : @expression
      @statements.each { |s| s.evaluate(scope) }
    end
  end
end

class ForEachNode < SuperNode
  def initialize(var, it, stmts)
    @var, @iterator, @statements = var, it, stmts
  end

  def evaluate(parent_scope)
    scope = Scope.new(parent_scope)
    while AssignmentNode.new(@var, @iterator.evaluate(scope)).evaluate(scope)
      @statements.each { |s| s.evaluate(scope) }
    end
  end
end

class FromNode < SuperNode
  def initialize(start, stop)
    @start, @stop = start, stop
    @has_been_initialized = false
  end

  def evaluate(scope)
    if not @has_been_initialized
      @has_been_initialized = true
      start = @start.class.superclass == SuperNode ? @start.evaluate(scope) : @start
      stop = @stop.class.superclass == SuperNode ? @stop.evaluate(scope) : @stop    
      if stop > start
        @range = (start..stop).step
      else
        @range = start.downto(stop)
      end
    end
    begin
      @range.next
    rescue StopIteration
      nil
    end
  end
end

class LookupNode < SuperNode
  def initialize(name)
    @name = name
  end

  def evaluate(scope)
    results = scope.get(@name)
    raise "ERROR: Variable does not exist!" unless results
    results
  end
end

class ExpressionNode < SuperNode
  def initialize(value)
    @value = value
  end
  def evaluate(scope)
    if @value.class.superclass == SuperNode
      @value.evaluate(scope)
    else
      @value
    end
  end
end

class BoolNode < SuperNode
  def initialize(value)
    @value = value
  end
  def evaluate(scope)
    if @value.class.superclass == SuperNode
      @value.evaluate(scope)
    else
      @value
    end
  end
end

class BoolOrNode < SuperNode
  def initialize(lh, rh)
    @lh, @rh = lh, rh
  end
  def evaluate(scope)
    @lh.evaluate(scope) or @rh.evaluate(scope)
  end
end

class BoolAndNode < SuperNode
  def initialize(lh, rh)
    @lh, @rh = lh, rh
  end
  def evaluate(scope)
    @lh.evaluate(scope) and @rh.evaluate(scope)
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
    value = @value.class.superclass == SuperNode ? @value.evaluate(scope) : @value
    File.open("f", "a") { |f| f.print value }
  end
end

class ComparisonNode < SuperNode
  def initialize(lh, op, rh, middle=nil)
    @lh, @op, @rh, @middle = lh, op, rh, middle
  end
  def evaluate(scope)
    lh = @lh.class.superclass == SuperNode ? @lh.evaluate(scope) : @lh
    rh = @rh.class.superclass == SuperNode ? @rh.evaluate(scope) : @rh
    middle = (@middle.class.superclass == SuperNode ? @middle.evaluate(scope) : @middle) if @middle
    case @op
    when '<' then lh < rh
    when '>' then lh > rh
    when '<=' then lh <= rh
    when '>=' then lh >= rh
    when 'between' then middle.between?([lh,rh].min, [lh, rh].max)
    when '==' then lh == rh
    end
  end
end

class AritmNode < SuperNode
  def initialize(lh, op, rh)
    @lh, @op, @rh = lh, op, rh
  end
  def evaluate(scope)
    lh = @lh.class.superclass == SuperNode ? @lh.evaluate(scope) : @lh
    rh = @rh.class.superclass == SuperNode ? @rh.evaluate(scope) : @rh
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
    @values.map { |a| a.class.superclass == SuperNode ? a.evaluate(scope) : a }
  end

  def +(array)
    ArrayNode.new(@values + array.values)
  end
end
