#!/usr/bin/env ruby -w

$KCODE = 'u'
require 'jcode'
require 'vcard'
require 'base64'
require 'test/unit'

class Test64 < Test::Unit::TestCase
  def testValidResult
	 s = "Polyfon zwitschernd a�en M�xchens V�gel R�ben, Joghurt und Quark"
	 assert_equal Base64.encode64(s).tr("\n", ''), s.to_b64
  end
end


