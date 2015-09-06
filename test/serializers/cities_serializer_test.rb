require 'test_helper'

class CitiesSerializerTest < Minitest::Test
  def setup
    @cities = [
      City.new('Araçatuba', 'aracatuba'),
      City.new('São Carlos', 'sao-carlos')
    ]
    @serializer = CitiesSerializer.new(@cities)
  end

  def test_that_cities_is_set
    assert_equal @cities, @serializer.cities
  end

  def test_to_message_output
    output = "Araçatuba: /aracatuba\n \nSão Carlos: /sao-carlos"
    assert_equal output, @serializer.to_message
  end
end