require 'test_helper'

class StatesSerializerTest < Minitest::Test
  def setup
    @states = [
      State.new('SP', nil),
      State.new('RS', nil)
    ]
    @serializer = StatesSerializer.new(@states)
  end

  def test_that_states_is_set
    assert_equal @states, @serializer.states
  end

  def test_to_message_output
    output = "SP\nRS"
    assert_equal output, @serializer.to_message
  end
end