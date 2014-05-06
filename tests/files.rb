#! /usr/bin/env ruby

require './tests/testclass'

class TestClass < PCTest
  def test_indentation
    assert_file("indent1.pc", "AACAABCCD")
  end

  def test_functions
    assert_file("functions.pc", "New output!Hej!Hej!Hej!Hej!Hej!New output!Hej!Hej!Hej!Hej!Hej!Hej!HHHEEEJJJ1111222233334444")
  end

  def test_return
    assert_file("returns.pc", "")
    assert_file("returns2.pc", "number is 1number is 2hejbla11bla11returnIfOnereturnifTworeturnifThreereturnif")
  end

  def test_longer_functions
    assert_file("fibonacci_iter.pc", "55 equals 55!\n")
    assert_file("fibonacci_recursive.pc", "55")
    assert_file("quicksort.pc", "[0, 1, 2, 3, 4, 4, 5, 9]")
    assert_output("write \"hej\", \"lol\"", "hejlol")
  end

  def test_index
    assert_file("index.pc", "123436")
  end
end
