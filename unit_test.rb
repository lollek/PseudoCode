require 'test/unit'
require './pseudocode.rb'

class TestPseudoCode < Test::Unit::TestCase
  def test_tokens
    pc = PseudoCode.new
    assert_equal(nil, pc.parse(""))
    puts "ASSERTING write(1.2)"
    assert_equal(1.2, pc.parse("write 1.2"))
    puts "ASSERTING write(1)"
    assert_equal(1, pc.parse("write 1"))
    puts "ASSERTING write(true)"
    assert_equal(true, pc.parse("write true or false"))
    puts "ASSERTING write(true)"
    assert_equal(true, pc.parse("write true"))
    puts "ASSERTING write(\"hej\")"
    assert_equal("\"hej\"", pc.parse("write \"hej\""))
  end
end
