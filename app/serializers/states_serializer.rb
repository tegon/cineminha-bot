class StatesSerializer
  attr_accessor :states

  def initialize(states)
    @states = states
  end

  def to_message
    states.map(&:name).join("\n")
  end
end