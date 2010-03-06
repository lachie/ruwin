require 'pp'
#require 'osx/cocoa'
#OSX.require_framework 'ScriptingBridge'

<<<<<<< HEAD
framework 'ScriptingBridge'
=======
class Object
  def tap
    yield self
    self
  end

  def tapp
    pp self
    self
  end
end

module Enumerable
  def eachtap
    each {|t| yield t}
    self
  end
end
>>>>>>> snowy

module Dimension
  def val(v)
    case v
    when nil
      nil
    when NSNumber
      v.to_i
    else
      v
    end
  end
end

class Point
  include Dimension
  attr_accessor :x, :y
  def initialize(vals)
    if vals
      @x = val(vals[0])
      @y = val(vals[1])
    end
  end
end
class Size
  include Dimension
  attr_accessor :width,:height
  def initialize(vals)
    if vals
      @width = val(vals[0])
      @height= val(vals[1])
    end
  end
end

class Ruwin
  def self.system_events
    @system_events ||= SBApplication.applicationWithBundleIdentifier "com.apple.SystemEvents"
  end
  
  def self.frontmost(options={},&block)
    process = system_events.applicationProcesses.find {|p| p.frontmost}
    options[:process] = process
    options[:target] = process.windows[0]

    new(options, &block)
  end
  
  def self.app(name,options={},&block)
    name = name.downcase
    app = system_events.applicationProcesses.find {|a| a.name.downcase == name}
    options[:process] = app
    options[:target] = app.windows[0]

    new(options, &block)
  end

  attr_accessor :origin, :size

  # convert strings to fourcc
  SIZE_CODE = 'ptsz'.unpack('N').first
  POSITION_CODE = 'posn'.unpack('N').first

  ACTIONS_CODE = 'actT'.unpack('N').first

  def initialize(options, &block)
    @process = options.delete(:process)
    @target = options.delete(:target)

    @origin = [nil,nil]
    @size   = [nil,nil]
    
    if block_given?
      block.arity == -1 ? instance_eval(block) : block[self]
    else
      @size   = options.delete(:size)
      @origin = options.delete(:origin)
    end
    
    position!
    bring_to_front!
  end

  def position!
    origin = @target.propertyWithCode(POSITION_CODE)
    size   = @target.propertyWithCode(SIZE_CODE)
    
    origin.setTo(absolute_origin(origin.get))
    size.setTo(absolute_size(size.get))
  end

  def bring_to_front!

    # none of these work
    #pid = @process.unixId
    #app = OSX::NSWorkspace.sharedWorkspace.launchedApplications.find {|a| a['NSApplicationProcessIdentifier'] == pid}

    #psn = app.values_at('NSApplicationProcessSerialNumberHigh','NSApplicationProcessSerialNumberLow').pack('L2')
    #OSX::SetFrontProcessWithOptions(psn,0)
    
    #if @process
    #  OSX::SBApplication.applicationWithProcessIdentifier(@process.unixId).activate
    #end

    #if raise_action = @target.elementArrayWithCode(ACTIONS_CODE).objectWithName('AXRaise')
    #  raise_action.perform
    #end
  end
  

  # screen adjusted for a constant menu bar height
  # TODO handle more than one screen
  MENU_BAR_HEIGHT = 22
  def screen
    unless @screen 
      @screen = NSScreen.mainScreen.frame
      @screen.size.height -= MENU_BAR_HEIGHT
    end

    @screen
  end

  def abs(value,screen_value,original_value)
    case value
    when nil
      original_value
    when Float
      Integer(screen_value * value)
    else
      value
    end
  end
  
  def absolute_size(original_size)
    abs_size      = Size.new(@size)
    original_size = Size.new(original_size)

    abs_size.width  = abs(abs_size.width , screen.size.width , original_size.width)
    abs_size.height = abs(abs_size.height, screen.size.height, original_size.height)

    [ abs_size.width, abs_size.height ]
  end

  def absolute_origin(original_origin)
    abs_origin      = Point.new(@origin)
    original_origin = Point.new(original_origin)

    abs_origin.x = abs(abs_origin.x, screen.size.width , original_origin.x)
    abs_origin.y = abs(abs_origin.y, screen.size.height, original_origin.y)

    abs_origin.y += MENU_BAR_HEIGHT

    [ abs_origin.x, abs_origin.y ]
  end

end

if $0 == __FILE__
  Ruwin.app('safari', :origin => [0,0], :size => [0.666,1.0])

  Ruwin.app('terminal') do |w|
    w.origin = [0.666,0]
    w.size   = [0.333,0.5]
  end

  Ruwin.frontmost(:origin => [nil,0], :size => [nil,1.0])
end
