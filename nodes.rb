class SuperNode; end

class ProgramNode < SuperNode
  def initialize(statements)
    @statements = statements
  end

  def evaluate
    @statements.each { |s| s.evaluate }
    nil
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
    @lh= lh
    @rh = rh
  end
  def evaluate
    @lh.evaluate or @rh.evaluate
  end
end

class BoolAndNode < SuperNode
  def initialize(lh, rh)
    @lh= lh
    @rh = rh
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
    File.open("f", "a") {|f| f.print @value.class.superclass == SuperNode ? @value.evaluate : @value }
  end
end

class ComparisonNode < SuperNode
  def initialize(lh, op, rh, middle=nil)
    @lh = lh
    @op = op
    @rh = rh
    @middle = middle
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
