#! /usr/bin/env ruby
# TODO: Try bool + int or array + bool or array + int and see what happens

require './tests/testclass'

class TestClass < PCTest
  def test_addition
    assert_output("write 1 plus 2", "3")
    assert_output("write 1 plus -2", "-1")
    assert_output("write -1 plus 2", "1")
    assert_output("write -1 plus -2", "-3")
  end

  def test_subtraction
    assert_output("write 2 minus 1", "1")
    assert_output("write 2 minus -1", "3")
    assert_output("write -2 minus 1", "-3")
    assert_output("write -2 minus -1", "-1")
  end

  def test_multiplication
    assert_output("write 2 times 3", "6")
    assert_output("write 2 times -3", "-6")
    assert_output("write -2 times 3", "-6")
    assert_output("write -2 times -3", "6")
  end

  def test_division
    assert_output("write 6 divided by 2", "3")
    assert_output("write 6 divided by -2", "-3")
    assert_output("write -6 divided by 2", "-3")
    assert_output("write -6 divided by -2", "3")
  end

  def test_modulo
    assert_output("write 6 modulo 4", "2")
    assert_output("write 6 modulo -4", "-2")
    assert_output("write -6 modulo 4", "2")
    assert_output("write -6 modulo -4", "-2")
  end

  def test_addition_addition
    assert_output("write 1 plus 2 plus 3", "6")
  end

  def test_addition_subtraction
    assert_output("write 1 plus 2 minus 3", "0")
  end

  def test_addition_multiplication
    assert_output("write (6 plus 3) times 2", "18")
    assert_output("write 6 plus (3 times 2)", "12")
    assert_output("write 6 plus 3 times 2", "12")
  end

  def test_subtraction_addition
    assert_output("write 1 minus 2 plus 3", "2")
  end

  def test_multiplication_addition
    assert_output("write 6 times 3 plus 2", "20")
    assert_output("write (6 times 3) plus 2", "20")
    assert_output("write 6 times (3 plus 2)", "30")
  end

  def test_addition_modulo
    assert_output("write 6 plus 3 modulo 2", "7")
    assert_output("write (6 plus 3) modulo 2", "1")
    assert_output("write 6 plus (3 modulo 2)", "7")
  end

  def test_modulo_addition
    assert_output("write 19 modulo 3 plus 1", "2")
    assert_output("write (19 modulo 3) plus 1", "2")
    assert_output("write 19 modulo (3 plus 1)", "3")
  end

  def test_modulo_subtraction
    assert_output("write 3 modulo 2 minus 10", "-9")
    assert_output("write (3 modulo 2) minus 10", "-9")
    assert_output("write 3 modulo (2 minus 10)", "-5")
  end

  def test_multiplication_modulo
    assert_output("write 6 times 3 modulo 2", "6")
    assert_output("write (6 times 3) modulo 2", "0")
    assert_output("write 6 times (3 modulo 2)", "6")
  end

  def test_modulo_multiplication
    assert_output("write 6 modulo 3 times 2", "0")
    assert_output("write (6 modulo 3) times 2", "0")
    assert_output("write 6 modulo (3 times 2)", "0")
  end
end
