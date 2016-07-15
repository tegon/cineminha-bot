class Crawler
  include HTTParty

  base_uri 'http://www.ingresso.com'
  debug_output $stderr

  attr_accessor :city

  def initialize(city)
    @city = city
  end

  def states
    response = self.class.get('/aracatuba/home')
    html = Nokogiri::HTML(response.response.body)
    text = html.css('script').map do |script|
      script.text if script.text.include?('var estados =')
    end.compact.first
    states_string = text.to_s.split('=')[1].gsub('estados', '').gsub(';', '').gsub('\'', '').strip
    JSON.parse(states_string)
  end

  def movies
    response = self.class.get("/#{ @city }/home/filtro/recuperadadosfiltro", query: { tipoevento: 'cinema' })
    response.parsed_response['Espetaculos'].map do |movie|
      Movie.new(movie['Nome'], movie['Id'], nil)
    end
  end

  def movies_with_image
    response = self.class.get("/#{ @city }/home")
    html = Nokogiri::HTML(response.response.body)
    html.css('#item0 li').map do |movie_html|
      name = movie_html.css('.title').text
      id = movie_html.css('a').attr('href').text.split('/').last
      image = movie_html.css('img').attr('src').text
      Movie.new(name, id, image)
    end
  end

  def movie_id(movie)
    response = self.class.get("/#{ @city }/home/espetaculo/cinema/#{ movie.id }")
    html = Nokogiri::HTML(response.response.body)
    html.css('#hdnEspetaculo').attr('value').text
  end

  def sessions_date
    time = Time.now
    time += 1 if time.hour > 22 # tomorrow sessions
    time.strftime('%Y%m%d')
  end

  def sessions(movie)
    response = self.class.get("/#{ @city }/home/espetaculo/horarios", query: { tipoEvento: 1, espetaculo: movie_id(movie), data: sessions_date })
    html = Nokogiri::HTML(response.response.body)
    sessions = []
    html.css('.content-tabela-horario .tabela-horario-local').map do |cine_html|
      cine = Cine.new(cine_html.css('.nome-local-espetaculo').text, cine_html.css('.bairro-local-espetaculo').text)
      cine_html.css('.lista-horarios-local li').map do |session_html|
        session_html.css('.mv-th-sc-it').each do |inner|
          sessions << Session.new(cine, session_html.css('h6.tipo-sessao').text, inner.css('.btn-lb-hour').text, inner.css('a').attr('sala-data').text)
        end
      end
    end

    sessions
  end
end
