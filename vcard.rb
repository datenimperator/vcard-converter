#
#  vcard.rb
#  xing2
#
#  Created by Christian on 17.04.10.
#  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
#

require 'osx/cocoa'
require 'iconv'
require 'base64'

module Exporters

  SOURCE_ENCODING = "ISO-8859-1".to_sym

  def converter(from, to)
    @converters ||= {}
    key = "#{from}:#{to}".to_sym
    if @converters.key?(key)
      return @converters[key]
    end
    
    return @converters[key] = Iconv.new("#{to}//IGNORE//TRANSLIT", from.to_s)
  end

  def to_2_1
    r = ["BEGIN:VCARD"]
    
    @attributes.each { |a|
      if a.key == :photo
        # base64 endode it and mark it as such
        a.value = Base64.encode64(a.value).split.join('')
        a.opts[:encoding] = 'BASE64'
      end
      tmp = a.value
      opts = a.opts? ? ";#{a.opt_string}" : ''
      if a.opts.key?(:charset) && (SOURCE_ENCODING.to_s != a.opts[:charset])
        c = converter(SOURCE_ENCODING, a.opts[:charset])
        begin
          tmp = c.iconv(a.value)
        rescue ex
          OSX::NSLog("Error while converting encoding: #{ex}")
        end
      end
      r << "#{a.name}#{opts}:#{tmp}"
    }
    r << "END:VCARD"
  end

end

class VCardAttribute
  attr_accessor :key, :name, :value, :opts
  
  def initialize(a, aValue)
    @key = a[0].downcase.to_sym
    @name = @key.to_s.upcase
    @value = aValue
    @opts = Hash.new
    a[1..-1].map{ |e| v=e.split("="); @opts[v[0].downcase.to_sym] = v[1]} if a.length>1
  end
  
  def to_s
    @value
  end
  
  def opts?
    @opts.size>0
  end
  
  def opt_string
    if @key == :photo
      r = []
      [:encoding, :value, :type].each{|k|
        r << "#{k.to_s.upcase}=#{@opts[k]}" if @opts.key?(k)
      }
      return r.join(';')
    end
    @opts.map{|k, v| "#{k.to_s.upcase}=#{v}" }.join(";")
  end
  
end

class VCard

  include Exporters

  def initialize(d)
    @attributes = []
    d.each { |line| self << line }
  end
  
  def << (line)
    pos = line.index(":")
    return if pos.nil?
    
    a, v = line[0..pos-1], line[pos+1..-1].chomp  
    @attributes << VCardAttribute.new(a.split(";"), v)
  end
  
  def external_image?
    self.attribute?(:photo) && self.photo.any?{ |attr| attr.opts[:value]=="URL" }
  end
  
  def to_s
    "#{self.uid}: #{self.fn}"
  end
  
  def attribute?(key)
    @attributes.any? { |a| a.key == key }
  end
  
  def remove_attribute(key)
    @attributes.delete_if {|c| c.key == key }
  end
  
  def method_missing(id, *args)
    @attributes.select { |a| a.key == id }
  end
  
end

