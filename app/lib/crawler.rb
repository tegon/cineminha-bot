class Crawler
  include HTTParty

  base_uri 'http://www.ingresso.com'
  debug_output $stderr

  attr_accessor :city

  def initialize(city)
    @city = city
  end

  def movies
    response = self.class.get("/#{ @city }/home/filtro/recuperadadosfiltro", query: { tipoevento: 'cinema' })
    response.parsed_response['Espetaculos'].map do |movie|
      Movie.new(movie['Nome'], movie['Id'])
    end
  end

  def movie_id(movie)
    response = self.class.get("/#{ @city }/home/espetaculo/cinema/#{ movie.id }")
    html = Nokogiri::HTML(response.response.body)
    html.css('#hdnEspetaculo').attr('value').text
  end

  def sessions_date
    date = Date.parse(Time.now.to_s) #+ 1
    date.strftime('%Y%m%d')
  end

  def sessions(movie)
    response = self.class.get("/#{ @city }/home/espetaculo/horarios", query: { tipoEvento: 1, espetaculo: movie_id(movie), data: sessions_date })
    html = Nokogiri::HTML(response.response.body)
    sessions = []
    html.css('.content-tabela-horario .tabela-horario-local').map do |cine_html|
      cine = Cine.new(cine_html.css('.nome-local-espetaculo').text, cine_html.css('.bairro-local-espetaculo').text)
      cine_html.css('.lista-horarios-local').map do |session_html|
        session_html.css('.mv-th-sc-it').each do |inner|
          sessions << Session.new(cine, session_html.css('h6.tipo-sessao').text, inner.css('.btn-lb-hour').text, inner.css('a').attr('sala-data').text)
        end
      end
    end

    sessions
  end
end