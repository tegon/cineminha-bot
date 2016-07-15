require 'test_helper'

class CrawlerTest < Minitest::Test
  def setup
    @crawler = Crawler.new('aracatuba')
  end

  def test_that_city_is_set
    assert_equal 'aracatuba', @crawler.city
  end

  def test_states_parser
    stub_request(:get, 'http://www.ingresso.com/aracatuba/home')
      .to_return(
        status: 200,
        body: respond_with_file('states.html')
      )

    states = @crawler.states
    assert_equal 26, states.size
    assert_equal 'AC', states.first.first
  end

  def test_movies_parser
    stub_request(:get, 'http://www.ingresso.com/aracatuba/home/filtro/recuperadadosfiltro')
      .with(query: { tipoevento: 'cinema' })
      .to_return(
        status: 200, headers: { content_type: 'application/json' },
        body: respond_with_file('movies.json')
      )

    movies = @crawler.movies
    assert_equal 12, movies.size
    assert_equal 'Corrente do mal', movies.first.name
    assert_equal Movie, movies.first.class
  end

  def test_movie_id_parser
    movie = Movie.new('Ted 2', 'ted-2', nil)

    stub_request(:get, "http://www.ingresso.com/aracatuba/home/espetaculo/cinema/#{ movie.id }")
      .to_return(
        status: 200,
        body: respond_with_file('movie_id.html')
      )

    assert_equal '11247', @crawler.movie_id(movie)
  end

  def test_sessions_parser
    movie = Movie.new('Ted 2', 'ted-2', nil)

    stub_request(:get, "http://www.ingresso.com/aracatuba/home/espetaculo/cinema/#{ movie.id }")
      .to_return(
        status: 200,
        body: respond_with_file('movie_id.html')
      )

    stub_request(:get, 'http://www.ingresso.com/aracatuba/home/espetaculo/horarios')
      .with(query: { tipoEvento: 1, espetaculo: '11247', data: @crawler.sessions_date })
      .to_return(
        status: 200,
        body: respond_with_file('sessions.html')
      )

    sessions = @crawler.sessions(movie)
    assert_equal 2, sessions.size
    assert_equal Session, sessions.first.class
    assert_equal '19:30', sessions.first.time
    assert_equal 'DUB', sessions.first.type
    assert_equal 'Cineflix Araçatuba', sessions.first.cine.name
    assert_equal 'Guanabara', sessions.first.cine.location
  end
end
