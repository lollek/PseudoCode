#! /usr/bin/env ruby

require './tests/testclass'

class TestClass < PCTest
  def test_range
    assert_output("for each number from 0 to 10 do\n  write number\n", "012345678910")
    assert_output("for each number from 10 to 0 do\n  write number\n", "109876543210")
    assert_output("testVar equals 2\nfor each number from testVar to -2 do\n  write number\n", "210-1-2")
    assert_output("testVar equals 2\nfor each number from -2 to testVar do\n  write number\n", "-2-1012")
    assert_output("testA equals 0\ntestB equals 10\nfor each number from testA to testB do\n  write number\n", "012345678910")
  end

  def test_array
    assert_output("for each number in [] do\n  write number\n", "")
    assert_output("for each number in [1] do\n  write number\n", "1")
    assert_output("for each number in [1,2] do\n  write number\n", "12")
    assert_output("for each number in [1,2,3] do\n  write number\n", "123")
    assert_output("for each number in [1,2,[3,4]] do\n  write number\n", "12[3, 4]")
    assert_output("testVar equals [4,5,6,[7,8,9]]\nfor each number in [1,2,[3,testVar]] do\n  write number\n", "12[3, [4, 5, 6, [7, 8, 9]]]")
    assert_output("for each number in [1,2,\"HEJHEJ\"] do\n  write number\n", "12HEJHEJ")
    assert_output("for each letter in \"alµaböaCLA\" do\n  write letter\n", "alµaböaCLA")
    assert_output("mystring equals \"hejsan123\"\nfor each letter in mystring do\n  write letter\n", "hejsan123")
  end
end
