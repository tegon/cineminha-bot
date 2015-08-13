class Session
  attr_accessor :cine, :type, :time, :room

  def initialize(cine, type, time, room)
    @cine = cine
    @type = type
    @time = time
    @room = room
  end
end