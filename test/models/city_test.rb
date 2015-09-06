require 'test_helper'

class CityTest < Minitest::Test
  def setup
    @city = City.new('Araçatuba', 'aracatuba')
  end

  def test_that_name_is_set
    assert_equal 'Araçatuba', @city.name
  end

  def test_that_permalink_is_set
    assert_equal 'aracatuba', @city.permalink
  end
end