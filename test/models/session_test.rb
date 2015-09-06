require 'test_helper'

class SessionTest < Minitest::Test
  def setup
    @cine = Cine.new('Cine Araújo', 'Nova York')
    @session = Session.new(@cine, 'LEG3D', '14:00', 'Sala 3')
  end

  def test_that_cine_is_set
    assert_equal @cine, @session.cine
  end

  def test_that_type_is_set
    assert_equal 'LEG3D', @session.type
  end

  def test_that_time_is_set
    assert_equal '14:00', @session.time
  end

  def test_that_room_is_set
    assert_equal 'Sala 3', @session.room
  end
end