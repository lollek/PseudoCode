#! /usr/bin/env ruby

require 'test/unit'
require './pseudocode.rb'

class TestPseudoCode < Test::Unit::TestCase
  def tokens
    `mkfifo f`
    f = File.open("f", IO::NONBLOCK, IO::RDONLY)
    pc = PseudoCode.new

    pc.parse("")
    assert_equal("", f.read)

    # Floats
    pc.parse("write 1.2")
    assert_equal("1.2", f.read)
    pc.parse("write -1.2")
    assert_equal("-1.2", f.read)

    # Integers
    pc.parse("write 1")
    assert_equal("1", f.read)
    pc.parse("write -1")
    assert_equal("-1", f.read)

    # Booleans
    pc.parse("write true")
    assert_equal("true", f.read)
    pc.parse("write false")
    assert_equal("false", f.read)

    # Strings
    pc.parse("write \"hej\"")
    assert_equal("\"hej\"", f.read)

    `rm f`
  end

  def arithm_expr
    `mkfifo f`
    f = File.open("f", IO::NONBLOCK, IO::RDONLY)

    pc = PseudoCode.new

    # Addition
    pc.parse("write 1 plus 2")
    assert_equal("3", f.read)

    # Subtraction
    pc.parse("write 2 minus 1")
    assert_equal("1", f.read)

    # Times
    pc.parse("write 2 times 3")
    assert_equal("6", f.read)

    # Divided by
    pc.parse("write 6 divided by 2")
    assert_equal("3", f.read)

    # Modulo
    pc.parse("write 6 modulo 4")
    assert_equal("2", f.read)

    # Complex
    pc.parse("write (6 plus 3) times 2")
    assert_equal("18", f.read)
    pc.parse("write 6 plus 3 times 2")
    assert_equal("12", f.read)
    pc.parse("write 6 plus 3 modulo 2")
    assert_equal("7", f.read)
    pc.parse("write 3 modulo 2 minus 10")
    assert_equal("-9", f.read)
    pc.parse("write 6 times 3 modulo 2")
    assert_equal("6", f.read)
    pc.parse("write 6 modulo 3 times 2")
    assert_equal("0", f.read)
    pc.parse("write 6 times 3 plus 2")
    assert_equal("20", f.read)
    pc.parse("write 6 plus 3 times 2")
    assert_equal("12", f.read)

    f.close
    `rm f`
  end

  def bool_expr
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

    f.close
    `rm f`
  end
end
