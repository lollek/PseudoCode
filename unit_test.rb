#! /usr/bin/env ruby

require 'test/unit'
require './pseudocode.rb'

class TestPseudoCode < Test::Unit::TestCase
  def test_tokens
    pc = PseudoCode.new
    assert_equal(nil, pc.parse(""))

    # Floats
    assert_equal(1.2, pc.parse("write 1.2"))
    assert_equal(-1.2, pc.parse("write -1.2"))

    # Integers
    assert_equal(1, pc.parse("write 1"))
    assert_equal(-1, pc.parse("write -1"))

    # Booleans
    assert_equal(true, pc.parse("write true"))
    assert_equal(false, pc.parse("write false"))

    # Strings
    assert_equal("\"hej\"", pc.parse("write \"hej\""))
  end

  def test_arithm_expr
    pc = PseudoCode.new

    # Addition
    assert_equal(2, pc.parse("write 1 plus 1"))
  end
end
