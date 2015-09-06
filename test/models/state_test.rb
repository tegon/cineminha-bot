require 'test_helper'

class StateTest < Minitest::Test
  def setup
    @cities = [City.new('Araçatuba', 'aracatuba')]
    @state = State.new('SP', @cities)
  end

  def test_that_name_is_set
    assert_equal 'SP', @state.name
  end

  def test_that_cities_is_set
    assert_equal @cities, @state.cities
  end
end