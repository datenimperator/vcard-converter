#
#  AppDelegate.rb
#  xing2
#
#  Created by Christian on 19.04.10.
#  Copyright (c) 2010 software-consultant.net. All rights reserved.
#

require 'osx/cocoa'

class AppDelegate < OSX::NSObject
  def applicationShouldOpenUntitledFile(sender)
    false
  end
  
  def applicationShouldTerminateAfterLastWindowClosed(sender)
    false
  end
end
