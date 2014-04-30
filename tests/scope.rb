#! /usr/bin/env ruby

require './tests/testclass'

class TestClass < PCTest
  def test_all_scopes
    assert_output("test equals 1\nif true then\n  test equals 2\n  write test\nwrite test\n", "22")
    assert_output("test equals 1\nif true then\n  testB equals 2\n  write testB\nwrite test\n", "21")
    assert_output("test equals 1\nif true then\n  test equals 2\n  write test\n", "2")
    assert_output("testVar equals 0\nwhile testVar is less than 10 do\n  write testVar\n  increase testVar by 1\nwrite testVar", "012345678910")
    assert_output("test equals 1\nif true then\n  testB equals 2\n  write testB\n  if true then\n    write test\n", "21")
    assert_output("test equals 1\nif true then\n  testB equals 2\n  write test\n  if true then\n    write testB\n", "12")
    assert_file("scope1.pc", "1")
  end
end
