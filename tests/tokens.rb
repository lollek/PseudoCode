#! /usr/bin/env ruby

require './tests/testclass'

class TestClass < PCTest
  def test_empty
    assert_output("", "")
  end

  def test_floats
    assert_output("write 1.2", "1.2")
    assert_output("write -1.2", "-1.2")
  end

  def test_integers
    assert_output("write 1", "1")
    assert_output("write -1", "-1")
  end

  def test_booleans
    assert_output("write true", "true")
    assert_output("write false", "false")
  end

  def test_strings
    assert_output("write \"hej\"", "hej")
  end

  def test_comments
    assert_output("#hej", "");
    assert_output("#hej\n", "");
  end

  def test_parentheses
    assert_output("write 1 plus 2", "3")
    assert_output("write 1 plus (2)", "3")
    assert_output("write (1) plus (2)", "3")
    assert_output("write ((1 plus 2) plus 3)", "6")
  end
end
