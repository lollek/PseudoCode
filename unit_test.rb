#! /usr/bin/env ruby

require 'test/unit'
require './pseudocode.rb'

class TestPseudoCode < Test::Unit::TestCase
  def tokens
    pc = PseudoCode.new
    assert_equal(nil, pc.parse(""))

    # Floats
    assert_equal(1.2, pc.parse("write 1.2"))
    assert_equal(-1.2, pc.parse("write -1.2"))

    # Integers
    assert_equal(1, pc.parse("write 1"))
    assert_equal(-1, pc.parse("write -1"))

    # Booleans
    assert_equal(true, pc.parse("write true"))
    assert_equal(false, pc.parse("write false"))

    # Strings
    assert_equal("\"hej\"", pc.parse("write \"hej\""))
  end

  def arithm_expr
    pc = PseudoCode.new

    # Addition
    assert_equal(3, pc.parse("write 1 plus 2"))

    # Subtraction
    assert_equal(1, pc.parse("write 2 minus 1"))

    # Times
    assert_equal(6, pc.parse("write 2 times 3"))

    # Divided by
    assert_equal(3, pc.parse("write 6 divided by 2"))

    # Modulo
    assert_equal(2, pc.parse("write 6 modulo 4"))

    # Complex
    assert_equal(18, pc.parse("write (6 plus 3) times 2"))
    assert_equal(12, pc.parse("write 6 plus 3 times 2"))
    assert_equal(7, pc.parse("write 6 plus 3 modulo 2"))
    assert_equal(-9, pc.parse("write 3 modulo 2 minus 10"))
    assert_equal(6, pc.parse("write 6 times 3 modulo 2"))
    assert_equal(0, pc.parse("write 6 modulo 3 times 2"))
    assert_equal(20, pc.parse("write 6 times 3 plus 2"))
    assert_equal(12, pc.parse("write 6 plus 3 times 2"))
  end

  def test_bool_expr
    pc = PseudoCode.new
    `mkfifo f`
    f = File.open("f", IO::NONBLOCK, IO::RDONLY)
    
    # not
    pc.parse("write not true")
    assert_equal("false", f.read())
    
    pc.parse("write not false")
    assert_equal("true", f.read())

    # and
    pc.parse("write false and true")
    assert_equal("false", f.read)
    pc.parse("write false and false")
    assert_equal("false", f.read)
    pc.parse("write true and true")
    assert_equal("true", f.read)
    pc.parse("write true and false")
    assert_equal("false", f.read)

    # or
    pc.parse("write false or true")
    assert_equal("true", f.read)
    pc.parse("write false or false")
    assert_equal("false", f.read)
    pc.parse("write true or true")
    assert_equal("true", f.read)
    pc.parse("write true or false")
    assert_equal("true", f.read)

    # Complex
    pc.parse("write (false and true) or false")
    assert_equal("false", f.read)
    pc.parse("write false and (true or false)")
    assert_equal("false", f.read)
    pc.parse("write (true and false) or true")
    assert_equal("true", f.read)
    pc.parse("write true and (false or true)")
    assert_equal("true", f.read)
    pc.parse("write false and true or false")
    assert_equal("false", f.read)
    pc.parse("write false or true and false")
    assert_equal("false", f.read)

    # Comparison
    ## Integers
    pc.parse("write 1 is less than 2")
    assert_equal("true", f.read)
    pc.parse("write 2 is less than 1")
    assert_equal("false", f.read)
    pc.parse("write 2 is greater than 1")
    assert_equal("true", f.read)
    pc.parse("write 1 is greater than 2")
    assert_equal("false", f.read)
    pc.parse("write 1 is between 10 and 0")
    assert_equal("true", f.read)
    pc.parse("write 0 is between 10 and 1")
    assert_equal("false", f.read)
    pc.parse("write 1 is 2 or less")
    assert_equal("true", f.read)
    pc.parse("write 100 is 2 or less")
    assert_equal("false", f.read)
    pc.parse("write 4 is 3 or more")
    assert_equal("true", f.read)
    pc.parse("write 4 is 4 or more")
    assert_equal("true", f.read)

    ## Floats
    pc.parse("write 1.0 is less than 2.0")
    assert_equal("true", f.read)
    pc.parse("write 2.0 is less than 1.00")
    assert_equal("false", f.read)
    pc.parse("write 2.0 is greater than 1.00")
    assert_equal("true", f.read)
    pc.parse("write 1.00 is greater than 2.0")
    assert_equal("false", f.read)
    pc.parse("write 1.00000 is between 10.0 and 0.0")
    assert_equal("true", f.read)
    pc.parse("write 0.0 is between 10.0 and 1.0")
    assert_equal("false", f.read)
    pc.parse("write 1.0 is 2.0 or less")
    assert_equal("true", f.read)
    pc.parse("write 100.00 is 2.0 or less")
    assert_equal("false", f.read)
    pc.parse("write 4.0 is 3.0 or more")
    assert_equal("true", f.read)
    pc.parse("write 4.0 is 4.0 or more")
    assert_equal("true", f.read)

    ## Float/Integer mix
    pc.parse("write 1 is less than 2.0")
    assert_equal("true", f.read)
    pc.parse("write 2 is less than 1.00")
    assert_equal("false", f.read)
    pc.parse("write 2 is greater than 1.00")
    assert_equal("true", f.read)
    pc.parse("write 10 is greater than 2.0")
    assert_equal("true", f.read)
    pc.parse("write 1 is between 10.0 and 0.0")
    assert_equal("true", f.read)
    pc.parse("write 0 is between 10.0 and 1.0")
    assert_equal("false", f.read)
    pc.parse("write 1 is 2.0 or less")
    assert_equal("true", f.read)
    pc.parse("write 100 is 2.0 or less")
    assert_equal("false", f.read)
    pc.parse("write 4 is 3.0 or more")
    assert_equal("true", f.read)
    pc.parse("write 4 is 4.0 or more")
    assert_equal("true", f.read)
    
    `rm f`
  end
end
