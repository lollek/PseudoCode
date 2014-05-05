#! /usr/bin/env ruby

require './tests/testclass'

class TestClass < PCTest
  def test_statements
    assert_output("write 1\nwrite 2", "12")
    assert_output("write 1 plus 43\nwrite 4 minus 3", '441')
  end
end
