#! /usr/bin/env ruby

require 'test/unit'
require './pseudocode.rb'

class TestPseudoCode < Test::Unit::TestCase
  def test_tokens
    pc = PseudoCode.new
    assert_equal(nil, pc.parse(""))
    assert_equal(1.2, pc.parse("write 1.2"))
    assert_equal(-1.2, pc.parse("write -1.2"))
    assert_equal(1, pc.parse("write 1"))
    assert_equal(-1, pc.parse("write -1"))
    assert_equal(true, pc.parse("write true"))
    assert_equal(false, pc.parse("write false"))
    assert_equal("\"hej\"", pc.parse("write \"hej\""))
  end
end
