class SuperNode
  def initialize value
    @value = value
    @@variables = {}
  end
end

class ProgramNode < SuperNode
  def initialize(statements)
    @statements = statements
  end

  def evaluate
    @statements.each { |s| s.evaluate}
    nil
  end
end

class AssignmentNode < SuperNode
  def initialize(name, value)
    @name, @value = name, value        
  end

  def evaluate
    @value = @value.evaluate if @value.class.superclass == SuperNode
    @@variables[@name] = @value
  end
end

class LookupNode < SuperNode
  def initialize(name)
    @name = name
  end

  def evaluate
    if not @@variables.include? @name
      raise "ERROR: Variable does not exist!"
    end
    @@variables[@name]
  end
end

class BoolNode < SuperNode
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
  def evaluate
    @value.evaluate == false
  end
end

class WriteNode < SuperNode
  def evaluate
    @value = @value.evaluate if @value.class.superclass == SuperNode
    File.open("f", "a") { |f| f.print @value }
  end
end

class ComparisonNode < SuperNode
  def initialize(lh, op, rh, middle=nil)
    @lh, @op, @rh, @middle = lh, op, rh, middle
  end
  def evaluate
    case @op
    when '<' then @lh < @rh
    when '>' then @lh > @rh
    when '<=' then @lh <= @rh
    when '>=' then @lh >= @rh
    when 'between' then @middle.between?([@lh,@rh].min, [@lh, @rh].max)
    when '==' then @lh == @rh
    end
  end
end

class ArithmNode < SuperNode
  def initialize(lh, op, rh)
    @lh, @op, @rh = lh, op, rh
  end
  def evaluate
    @lh = @lh.evaluate if @lh.class.superclass == SuperNode
    @rh = @rh.evaluate if @rh.class.superclass == SuperNode
    case @op
    when '+' then @lh + @rh
    when '-' then @lh - @rh
    when '%' then @lh % @rh
    when '*' then @lh * @rh
    when '/' then @lh / @rh
    end
  end
end
