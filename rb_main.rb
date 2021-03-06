#
#  rb_main.rb
#  xing2
#
#  Created by Christian on 17.04.10.
#  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
#

require 'osx/cocoa'
require 'iconv'

$KCODE = 'u'
# $DEBUG = true

def rb_main_init
  path = OSX::NSBundle.mainBundle.resourcePath.fileSystemRepresentation
  rbfiles = Dir.entries(path).select {|x| /\.rb\z/ =~ x}
  rbfiles -= [ File.basename(__FILE__) ]
  rbfiles.each do |path|
    require( File.basename(path) )
  end
end

if $0 == __FILE__ then
  rb_main_init
  OSX.NSApplicationMain(0, nil)
end
