#! /usr/bin/env ruby
# TODO: Test modification on floats, bool, array and see what happens

require './tests/testclass'

class TestClass < PCTest
  def test_int
    assert_output("testVar equals 4 plus 1 times 2\nwrite testVar", "6")
    assert_output("testVarA equals 2\ntestVarB equals testVarA\nwrite testVarB", "2")
    assert_output("testVarA equals 2\ntestVarB equals 1 plus testVarA\nwrite testVarB", "3")
    assert_output("testVarA equals 2\ntestVarB equals testVarA plus 1\nwrite testVarB", "3")
    assert_output("testVarA equals 2\ntestVarB equals (testVarA plus 1)\nwrite testVarB", "3")
  end

  def test_int_modifications
    assert_output("testVar equals 0\nincrease testVar by 4\nwrite testVar", "4")
    assert_output("testVar equals 0\ndecrease testVar by 4\nwrite testVar", "-4")
    assert_output("testVar equals 2\nmultiply testVar by 4\nwrite testVar", "8")
    assert_output("testVar equals 8\ndivide testVar by 4\nwrite testVar", "2")
  end

  def test_bools
    assert_output("testVar equals true or false\nwrite testVar", "true")
  end

  def test_arrays
    assert_output("testVar equals [1,2,3,5,6]\nwrite testVar", "[1, 2, 3, 5, 6]")
    assert_output("testVar equals [\"A\", \"B\", \"C\"]\nwrite testVar", '["A", "B", "C"]')
    assert_output("testVar equals [1,2,[4,5,6],3]\nwrite testVar", "[1, 2, [4, 5, 6], 3]")
    assert_output("testVar equals [1]\nwrite testVar", "[1]")
    assert_output("testVar equals [1,2]\nwrite testVar", "[1, 2]")
    assert_output("testVar equals [4]\nwrite testVar", "[4]")
    assert_output("testVar equals [4,5]\nwrite testVar", "[4, 5]")
    assert_output("testVar equals [4,5,6]\nwrite testVar", "[4, 5, 6]")
    assert_output("testArray equals [4,5,6]\ntestVar equals [1,2,testArray,3]\nwrite testVar", "[1, 2, [4, 5, 6], 3]")
  end
end

