#! /usr/bin/env ruby

require './tests/testclass'

class TestClass < PCTest
  def test_all
    assert_output("testVar equals 0\nwhile testVar is less than 10 do\n  write testVar\n  increase testVar by 1\n\n", "0123456789")
  end
end
