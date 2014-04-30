#! /usr/bin/env ruby

require './tests/testclass'

class TestClass < PCTest
  def test_not
    assert_output("write not true", "false")
    assert_output("write not false", "true")
  end

  def test_and
    assert_output("write false and true", "false")
    assert_output("write false and false", "false")
    assert_output("write true and true", "true")
    assert_output("write true and false", "false")
  end

  def test_or
    assert_output("write false or true", "true")
    assert_output("write false or false", "false")
    assert_output("write true or true", "true")
    assert_output("write true or false", "true")
  end

  def test_is
    assert_output("write 4 is 4", "true")
    assert_output("panda equals 42\nwrite panda is panda", "true")
    assert_output("panda equals 42\nwrite panda is 42", "true")
    assert_output("panda equals 42\nwrite 42 is panda", "true")
    assert_output("panda equals 42\nwrite 43 is panda", "false")
  end

  def test_and_or
    assert_output("write (false and true) or false", "false")
    assert_output("write false and (true or false)", "false")
    assert_output("write (true and false) or true", "true")
    assert_output("write true and (false or true)", "true")
    assert_output("write false and true or false", "false")
    assert_output("write false or true and false", "false")
  end

  def test_compare_integers
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
  end

  def test_compare_floats
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
  end

  def test_compare_float_integer_mix
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

end
