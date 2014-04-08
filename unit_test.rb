#! /usr/bin/env ruby

require 'test/unit'
require './pseudocode.rb'

class TestPseudoCode < Test::Unit::TestCase
  def initialize(arg)
    `mkfifo f` unless File.exists? "f"
    @fifo = File.open("f", IO::NONBLOCK, IO::RDONLY)
    @pc = PseudoCode.new
    super(arg)
  end

  def assert_output(command, result)
    @pc.parse(command)
    assert_equal(result, @fifo.read)
    assert_equal("", @fifo.read)
  end

  def assert_file(filename, result)
    @pc.parse(File.read("./test_cases/#{filename}"))
    assert_equal(result, @fifo.read)
    assert_equal("", @fifo.read)
  end
  
  def tokens
    assert_output("", "")

    # Floats
    assert_output("write 1.2", "1.2")
    assert_output("write -1.2", "-1.2")

    # Integers
    assert_output("write 1", "1")
    assert_output("write -1", "-1")

    # Booleans
    assert_output("write true", "true")
    assert_output("write false", "false")

    # Strings
    assert_output("write \"hej\"", "hej")
  end

  def arithm_expr
    # Addition
    assert_output("write 1 plus 2", "3")

    # Subtraction
    assert_output("write 2 minus 1", "1")

    # Times
    assert_output("write 2 times 3", "6")

    # Divided by
    assert_output("write 6 divided by 2", "3")

    # Modulo
    assert_output("write 6 modulo 4", "2")

    # Complex
    assert_output("write (6 plus 3) times 2", "18")
    assert_output("write 6 plus (3 times 2)", "12")
    assert_output("write 6 plus 3 times 2", "12")
    assert_output("write 6 plus 3 modulo 2", "7")
    assert_output("write (6 plus 3) modulo 2", "1")
    assert_output("write 6 plus (3 modulo 2)", "7")
    assert_output("write 3 modulo 2 minus 10", "-9")
    assert_output("write (3 modulo 2) minus 10", "-9")
    assert_output("write 3 modulo (2 minus 10)", "-5")
    assert_output("write 6 times 3 modulo 2", "6")
    assert_output("write (6 times 3) modulo 2", "0")
    assert_output("write 6 times (3 modulo 2)", "6")
    assert_output("write 6 modulo 3 times 2", "0")
    assert_output("write (6 modulo 3) times 2", "0")
    assert_output("write 6 modulo (3 times 2)", "0")
    assert_output("write 6 times 3 plus 2", "20")
    assert_output("write (6 times 3) plus 2", "20")
    assert_output("write 6 times (3 plus 2)", "30")
    assert_output("write 6 plus 3 times 2", "12")
    assert_output("write (6 plus 3) times 2", "18")
    assert_output("write 6 plus (3 times 2)", "12")
  end

  def bool_expr
    # not
    assert_output("write not true", "false")
    assert_output("write not false", "true")

    # and
    assert_output("write false and true", "false")
    assert_output("write false and false", "false")
    assert_output("write true and true", "true")
    assert_output("write true and false", "false")

    # or
    assert_output("write false or true", "true")
    assert_output("write false or false", "false")
    assert_output("write true or true", "true")
    assert_output("write true or false", "true")

    # Complex
    assert_output("write (false and true) or false", "false")
    assert_output("write false and (true or false)", "false")
    assert_output("write (true and false) or true", "true")
    assert_output("write true and (false or true)", "true")
    assert_output("write false and true or false", "false")
    assert_output("write false or true and false", "false")

    # Comparison
    ## Integers
    assert_output("write 1 is less than 2", "true")
    assert_output("write 2 is less than 1", "false")
    assert_output("write 2 is greater than 1", "true")
    assert_output("write 1 is greater than 2", "false")
    assert_output("write 1 is between 10 and 0", "true")
    assert_output("write 0 is between 10 and 1", "false")
    assert_output("write 1 is 2 or less", "true")
    assert_output("write 100 is 2 or less", "false")
    assert_output("write 4 is 3 or more", "true")
    assert_output("write 4 is 4 or more", "true")

    ## Floats
    assert_output("write 1.0 is less than 2.0", "true")
    assert_output("write 2.0 is less than 1.00", "false")
    assert_output("write 2.0 is greater than 1.00", "true")
    assert_output("write 1.00 is greater than 2.0", "false")
    assert_output("write 1.00000 is between 10.0 and 0.0", "true")
    assert_output("write 0.0 is between 10.0 and 1.0", "false")
    assert_output("write 1.0 is 2.0 or less", "true")
    assert_output("write 100.00 is 2.0 or less", "false")
    assert_output("write 4.0 is 3.0 or more", "true")
    assert_output("write 4.0 is 4.0 or more", "true")

    ## Float/Integer mix
    assert_output("write 1 is less than 2.0", "true")
    assert_output("write 2 is less than 1.00", "false")
    assert_output("write 2 is greater than 1.00", "true")
    assert_output("write 10 is greater than 2.0", "true")
    assert_output("write 1 is between 10.0 and 0.0", "true")
    assert_output("write 0 is between 10.0 and 1.0", "false")
    assert_output("write 1 is 2.0 or less", "true")
    assert_output("write 100 is 2.0 or less", "false")
    assert_output("write 4 is 3.0 or more", "true")
    assert_output("write 4 is 4.0 or more", "true")
  end

  def stmts
    assert_output("write 1\nwrite 2", "12")
    assert_output("write 1 plus 43\nwrite 4 minus 3", '441')
  end

  def assignment
    assert_output("testVar equals 4 plus 1 times 2\nwrite testVar", "6")
    assert_output("testVarA equals 2\ntestVarB equals testVarA\nwrite testVarB", "2")
    assert_output("testVarA equals 2\ntestVarB equals 1 plus testVarA\nwrite testVarB", "3")
    assert_output("testVarA equals 2\ntestVarB equals testVarA plus 1\nwrite testVarB", "3")
    assert_output("testVarA equals 2\ntestVarB equals (testVarA plus 1)\nwrite testVarB", "3")
    assert_output("testVar holds 1,2,3,5,6\nwrite testVar", "[1, 2, 3, 5, 6]")
    assert_output("testVar holds \"A\", \"B\", \"C\"\nwrite testVar", '["A", "B", "C"]')
    assert_output("testVar holds 1,2,[4,5,6],3\nwrite testVar", "[1, 2, [4, 5, 6], 3]")
    assert_output("testVar holds 1\nwrite testVar", "[1]")
    assert_output("testVar holds 1,2\nwrite testVar", "[1, 2]")
    assert_output("testVar equals [4]\nwrite testVar", "[4]")
    assert_output("testVar equals [4,5]\nwrite testVar", "[4, 5]")
    assert_output("testVar equals [4,5,6]\nwrite testVar", "[4, 5, 6]")
    assert_output("testArray holds 4,5,6\ntestVar holds 1,2,testArray,3\nwrite testVar", "[1, 2, [4, 5, 6], 3]")
  end

  def variables
    assert_output("testVar equals 4 plus 1\nwrite testVar", "5")
    assert_output("testVarA equals 4\ntestVarB equals testVarA plus testVarA", "")
    assert_output("testVarA equals 4 plus 1\ntestVarB equals testVarA plus 1\nwrite testVarB", "6")
    assert_output("testVar equals 4 plus 1\ntestVar equals testVar plus 1\nwrite testVar", "6")
    assert_output("testVar equals true or false\nwrite testVar", "true")
    # Raises ERROR
    # assert_output("testVar equals testVarABC plus 1\nwrite testVar", "5")
    assert_output("testVar equals 0\nincrease testVar by 4\nwrite testVar", "4")
    assert_output("testVar equals 0\ndecrease testVar by 4\nwrite testVar", "-4")
    assert_output("testVar equals 2\nmultiply testVar by 4\nwrite testVar", "8")
    assert_output("testVar equals 8\ndivide testVar by 4\nwrite testVar", "2")
  end

#  def input
#    assert_output("read to testVar\nwrite testVar", "hej")
#  end

 def if
    assert_output("if true then\n  write \"TRUE\"\n", "TRUE")
    assert_output("if false then\n  write \"FALSE\"\n", "")
    assert_output("if true then\n  write \"TRUE\"\n  testVar equals 42\n  write testVar\n", "TRUE42")
    assert_output("if true then\n  write \"TRUE\"\n  testVar equals \"FALSE\"\n  write testVar\n", "TRUEFALSE")
    assert_output("testVar equals true\nif testVar then\n  write \"TRUE\"\n", "TRUE")
  end

  def elseif
    assert_output("testVar equals true\nif testVar then\n  write 1\nelse if testVar then\n  write 0\n", "1")
    assert_output("testVar equals false\nif testVar then\n  write 1\nelse if not testVar then\n  write 0\n", "0")
    assert_output("testVarA equals 5\ntestVarB equals 2\nif testVarA is between 10 and testVarB then\n  write 1\nelse if not testVar then\n  write 0\n", "1")
    assert_output("if false then\n  write 0\nelse if false then\n  write 0\nelse if true then\n  write 1\n", "1")
    assert_output("if false then\n  write 0\nelse if true then\n  write 0\nelse if true then\n  write 1\n", "0")
  end

  def else
    assert_output("if false then\n  write 0\nelse\n  write 1\n", "1")
    assert_output("if false then\n  write 0\nelse if true then\n  write 0\nelse\n  write 1\n", "0")
    assert_output("if false then\n  write 0\nelse if false then\n  write 0\nelse\n  write 1\n", "1")
  end

  def while
      assert_output("testVar equals 0\nwhile testVar is less than 10 do\n  write testVar\n  increase testVar by 1\n\n", "0123456789")
  end

  def foreach
    assert_output("for each number from 0 to 10 do\n  write number\n", "012345678910")
    assert_output("for each number from 10 to 0 do\n  write number\n", "109876543210")
    assert_output("testVar equals 2\nfor each number from testVar to -2 do\n  write number\n", "210-1-2")
    assert_output("testVar equals 2\nfor each number from -2 to testVar do\n  write number\n", "-2-1012")
    assert_output("testA equals 0\ntestB equals 10\nfor each number from testA to testB do\n  write number\n", "012345678910")
  end

  def scope
    assert_output("test equals 1\nif true then\n  test equals 2\n  write test\nwrite test\n", "22")
    assert_output("test equals 1\nif true then\n  testB equals 2\n  write testB\nwrite test\n", "21")
    assert_output("test equals 1\nif true then\n  test equals 2\n  write test\n", "2")
    assert_output("testVar equals 0\nwhile testVar is less than 10 do\n  write testVar\n  increase testVar by 1\nwrite testVar", "012345678910")
    assert_output("test equals 1\nif true then\n  testB equals 2\n  write testB\n  if true then\n    write test\n", "21")
    assert_output("test equals 1\nif true then\n  testB equals 2\n  write test\n  if true then\n    write testB\n", "12")
  end

  def indentation
#    assert_file("indent1.pc", "AACAABCCD")
  end
end
