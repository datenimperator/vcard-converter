#
#  MyDocument.rb
#  xing2
#
#  Created by Christian on 17.04.10.
#  Copyright (c) 2010 __MyCompanyName__. All rights reserved.
#


require 'osx/cocoa'
require 'tempfile'

class ImageDownloadOperation < OSX::NSOperation

  include OSX

  attr_accessor :card, :crop
  
  def initialize
    @crop = false
  end

  def main
    @card.photo.each { |photo|
      if photo.opts[:value]=="URL"
        image = NSImage.create_with_url(photo.value)
        data = image.representations[0].representationUsingType_properties(NSJPEGFileType, nil)
        
        if data.nil?
          return
        end
        if data.length<1
          NSLog("Empty response: #{data.length} bytes available")
          return
        end
        begin
          imagedata = data.bytes.bytestr(data.length)
          imagedata = perform_crop(imagedata) if (@crop == true)

          photo.opts = {:type =>'JPEG'}
          photo.value = imagedata
        rescue RuntimeError => err
          NSLog("Error #{err}")
        end

      end
    }
    NSNotificationCenter.defaultCenter.postNotificationName_object('download_finished', nil)
  end
  
  private
  
  def perform_crop(imagedata)
    res = nil
    width = height = 140
    _if = Tempfile.new('tmp-xing')
    _if.write imagedata
    _if.flush
    _of = "#{_if.path}-out"

    if system("/usr/bin/sips -s format jpeg -c #{height} #{width} #{_if.path} --out #{_of} > /dev/null 2>&1")
      File.open(_of, "rb"){ |result|
        res = result.read
        system("rm #{_of}")
      }
    end
    _if.unlink
    
    return res unless res.nil?
    
    imagedata
  end
  
end

class VCardDocument < OSX::NSDocument

  include OSX
  
  ib_outlets :convert, :crop, :clean, :open
  ib_outlets :progress, :status, :btnConvert
  
  EXTRA_DATA = [:note, :class, :prodid]
  
  def initialize
    @convert = @crop = @clean = @open = @status = @progress = @btnConvert = nil
    @cards = []
    @downloads = 0
    
    @queue = NSOperationQueue.alloc.init
    @queue.setMaxConcurrentOperationCount(1)
  end
  
  def dealloc
    NSNotificationCenter.defaultCenter.removeObserver(self)
    super_dealloc
  end

  def windowControllerDidLoadNib(controller)  
    # Super.
    super_windowControllerDidLoadNib(controller)
    
    # 'Image loaded' notification.
    NSNotificationCenter.defaultCenter.addObserver_selector_name_object(
      self,
 	    'handleDownloadFinished:',
	    'download_finished',
	    nil
    )
  end
  
  def awakeFromNib
    update_status
  end

  def windowNibName
    # Implement this to return a nib to load OR implement
    # -makeWindowControllers to manually create your controllers.
    return "VCardDocument"
  end
  
  def handleConvertBtn(sender)
    @btnConvert.setEnabled(false)
    if @clean.state == 1
      @cards.each{|c|
        EXTRA_DATA.each {|a|
          c.remove_attribute(a)
        }
      }
    end
    if @convert.state == 1
      external_cards = @cards.select {|c| c.external_image? }
      # external_cards = @cards[0..1]
      @progress.setMaxValue(external_cards.length.to_f)
      @progress.setDoubleValue(0.0)
      external_cards.each{ |c|
        op = ImageDownloadOperation.new
        op.card = c
        op.crop = (@crop.state == 1)
        @queue.addOperation(op)
        @downloads += 1
      }
    end
  end
  ib_action :handleConvertBtn
  
  def handleDownloadFinished(notification)
    @progress.setDoubleValue(@progress.doubleValue + 1.0)
    @downloads -= 1
    updateChangeCount(NSChangeDone)
    if @downloads==0
      @progress.setHidden(true)
      update_status
      NSBeep()
    end
  end
  
  def performConvertClick(sender)
    @crop.setEnabled(@convert.state == 1)
  end
  ib_action :performConvertClick
  
  def update_status
    return if (@status.nil? || @cards.nil?)
    external_cards = @cards.select {|c| c.external_image? }
    unclean_cards = @cards.select {|c| EXTRA_DATA.any? {|a| c.attribute? a }}
    
    @status.setStringValue("#{external_cards.length}/#{unclean_cards.length}/#{@cards.length}")
    
    @clean.setEnabled( !unclean_cards.empty? )
    @convert.setEnabled( !external_cards.empty? )
    @crop.setEnabled( !external_cards.empty? )
    @btnConvert.setEnabled( !(unclean_cards.empty? && external_cards.empty?) )
  end
  
  def readFromData_ofType_error(rawData, type, err)
    if type == 'vCard'
      strData = rawData.bytes.bytestr(rawData.length)
      return false if strData.nil?
      data = nil
      strData.each { |line|
        case line.strip
          when /^BEGIN:VCARD/
            data = []
          when /^END:VCARD/
            @cards << VCard.new(data) unless data.nil?
            data = nil
          else
            data << line unless data.nil?
        end
      }
      update_status
      return true
    end

    false
  end
  
  def dataOfType_error(type, err)
    if type=='vCard'
      res = []
      @cards.each_with_index do |c, i|
        res += c.to_2_1
      end
      return NSData.create_with_str(res.join("\n"))
    end
    nil
  end

end
