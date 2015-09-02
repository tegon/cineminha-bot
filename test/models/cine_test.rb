require 'test_helper'

class CineTest < Minitest::Test
  def setup
    @cine = Cine.new('Cine Araújo', 'Nova York')
  end

  def test_that_name_is_set
    assert_equal 'Cine Araújo', @cine.name
  end

  def test_that_location_is_set
    assert_equal 'Nova York', @cine.location
  end
end