require 'test_helper'

class MovieTest < Minitest::Test
  def setup
    @movie = Movie.new('Minions', 'minions', nil)
  end

  def test_that_name_is_set
    assert_equal 'Minions', @movie.name
  end

  def test_that_id_is_set
    assert_equal 'minions', @movie.id
  end
end
