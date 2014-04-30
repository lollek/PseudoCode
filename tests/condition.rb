#! /usr/bin/env ruby
# TODO: Test "if 1" / "if 0", "if -1", if "[]", if "[1,2,3]"

require './tests/testclass'

class TestClass < PCTest
  def test_if
    assert_output("if true then\n  write \"TRUE\"\n", "TRUE")
    assert_output("if false then\n  write \"FALSE\"\n", "")
    assert_output("if true then\n  write \"TRUE\"\n  testVar equals 42\n  write testVar\n", "TRUE42")
    assert_output("if true then\n  write \"TRUE\"\n  testVar equals \"FALSE\"\n  write testVar\n", "TRUEFALSE")
    assert_output("testVar equals true\nif testVar then\n  write \"TRUE\"\n", "TRUE")
  end

  def test_elseif
    assert_output("testVar equals true\nif testVar then\n  write 1\nelse if testVar then\n  write 0\n", "1")
    assert_output("testVar equals false\nif testVar then\n  write 1\nelse if not testVar then\n  write 0\n", "0")
    assert_output("testVarA equals 5\ntestVarB equals 2\nif testVarA is between 10 and testVarB then\n  write 1\nelse if not testVar then\n  write 0\n", "1")
    assert_output("if false then\n  write 0\nelse if false then\n  write 0\nelse if true then\n  write 1\n", "1")
    assert_output("if false then\n  write 0\nelse if true then\n  write 0\nelse if true then\n  write 1\n", "0")
  end

  def test_else
    assert_output("if false then\n  write 0\nelse\n  write 1\n", "1")
    assert_output("if false then\n  write 0\nelse if true then\n  write 0\nelse\n  write 1\n", "0")
    assert_output("if false then\n  write 0\nelse if false then\n  write 0\nelse\n  write 1\n", "1")
  end

end
