#! /usr/bin/env ruby
# -*- coding: utf-8 -*-

$DEBUG_MODE = true
require 'test/unit'
require './pseudocode.rb'

class PCTest < Test::Unit::TestCase
  def initialize(arg)
    `mkfifo f` unless File.exists? "f"
    @fifo = File.open("f", IO::NONBLOCK, IO::RDONLY)
    @pc = PseudoCode.new
    super(arg)
  end

  def assert_output(command, result)
    @pc.parse(command)
    assert_equal(result, @fifo.read)
    assert_equal("", @fifo.read)
  end

  def assert_file(filename, result)
    @pc.parse(File.read("./tests/code/#{filename}"))
    assert_equal(result, @fifo.read)
    assert_equal("", @fifo.read)
  end
end
