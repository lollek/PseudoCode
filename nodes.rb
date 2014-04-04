class SuperNode
  def initialize_global_variables
    @@variables = {}
  end
end

class ProgramNode < SuperNode
  def initialize(statements)
    @statements = statements
    initialize_global_variables
  end

  def evaluate
    @statements.each { |s| s.evaluate}
    nil
  end
end

class AssignmentNode < SuperNode
  def initialize(name, value, op=nil)
    @name, @value, @op = name, value, op       
  end

  def evaluate
    value = @value.class.superclass == SuperNode ? @value.evaluate : @value
    if @op != nil and not @@variables.include? @name
      raise "ERROR: Variable does not exist!"
    end
    case @op
    when nil then @@variables[@name] = value
    when '+=' then @@variables[@name] += value
    when '-=' then @@variables[@name] -= value
    when '*=' then @@variables[@name] *= value
    when '/=' then @@variables[@name] /= value
    when 'array' then @@variables[@name] = value.map { |a| value.class.superclass == SuperNode ? a.evaluate : a }
    end
  end
end

class InputNode < SuperNode
  def initialize(var_name)
    @name = var_name
  end

  def evaluate
    input = gets
    input.chomp! if input
    AssignmentNode.new(@name, input).evaluate
  end
end

class ConditionNode < SuperNode
  def initialize(expr, stmts, elseif=nil)
    @expression, @statements, @elseif = expr, stmts, elseif
  end

  def evaluate
    expression = @expression.class.superclass == SuperNode ? @expression.evaluate : @expression
    if expression
      @statements.each { |s| s.evaluate}
    elsif @elseif != nil
      @elseif.evaluate
    end
    nil
  end
end

class WhileNode < SuperNode
  def initialize(expr, stmts)
    @expression, @statements = expr, stmts
  end

  def evaluate
    while @expression.class.superclass == SuperNode ? @expression.evaluate : @expression
      p @@variables
      @statements.each { |s| s.evaluate }
    end
  end
end
class LookupNode < SuperNode
  def initialize(name)
    @name = name
  end

  def evaluate
    if not @@variables.include? @name
      p @@variables
      raise "ERROR: Variable does not exist!"
    end
    @@variables[@name]
  end
end

class ExpressionNode < SuperNode
  def initialize(value)
    @value = value
  end
  def evaluate
    if @value.class.superclass == SuperNode
      @value.evaluate
    else
      @value
    end
  end
end

class BoolNode < SuperNode
  def initialize(value)
    @value = value
  end
  def evaluate
    if @value.class.superclass == SuperNode
      @value.evaluate
    else
      @value
    end
  end
end

class BoolOrNode < SuperNode
  def initialize(lh, rh)
    @lh, @rh = lh, rh
  end
  def evaluate
    @lh.evaluate or @rh.evaluate
  end
end

class BoolAndNode < SuperNode
  def initialize(lh, rh)
    @lh, @rh = lh, rh
  end
  def evaluate
    @lh.evaluate and @rh.evaluate
  end
end

class BoolNotNode < SuperNode
  def initialize(value)
    @value = value
  end
  def evaluate
    @value.evaluate == false
  end
end

class WriteNode < SuperNode
  def initialize(value)
    @value = value
  end
  def evaluate
    value = @value.class.superclass == SuperNode ? @value.evaluate : @value
    File.open("f", "a") { |f| f.print value }
  end
end

class ComparisonNode < SuperNode
  def initialize(lh, op, rh, middle=nil)
    @lh, @op, @rh, @middle = lh, op, rh, middle
  end
  def evaluate
    lh = @lh.class.superclass == SuperNode ? @lh.evaluate : @lh
    rh = @rh.class.superclass == SuperNode ? @rh.evaluate : @rh
    middle = (@middle.class.superclass == SuperNode ? @middle.evaluate : @middle) if @middle
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
  def evaluate
    lh = @lh.class.superclass == SuperNode ? @lh.evaluate : @lh
    rh = @rh.class.superclass == SuperNode ? @rh.evaluate : @rh
    case @op
    when '+' then lh + rh
    when '-' then lh - rh
    when '%' then lh % rh
    when '*' then lh * rh
    when '/' then lh / rh
    end
  end
end
