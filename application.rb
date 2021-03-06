class CineminhaBot < Sinatra::Application
  redis_server = {
    host: ENV['OPENSHIFT_REDIS_HOST'],
    port: ENV['OPENSHIFT_REDIS_PORT'],
    password: ENV['REDIS_PASSWORD']
  }

  set :cache, Sinatra::Cache::RedisStore.new(redis_server)

  configure :development do
    register Sinatra::Reloader
    also_reload 'app/**/*.rb'
    also_reload 'lib/**/*.rb'
  end

  before do
    content_type :json
    body = request.body.rewind && request.body.read
    @request_payload = JSON.parse(body) if body && body.length >= 2
    @session ||= Redis::Store::Factory.create(redis_server.merge(namespace: 'rack:session'))
  end

  helpers do
    include ApplicationHelper
    include CacheHelper
    include SessionHelper
    include ActiveSupport::Inflector
  end

  get '/messenger-webhook' do
    if params['hub.mode'] === 'subscribe' && params['hub.verify_token'] === ENV['MESSENGER_TOKEN']
      params['hub.challenge']
    else
      halt 403
    end
  end

  post '/messenger-webhook' do
    if @request_payload['object'] == 'page'
      @request_payload['entry'].each do |page_entry|
        page_entry['messaging'].each do |messaging_event|
          case
          when messaging_event['message'] then received_message(messaging_event)
          when messaging_event['postback'] then received_postback(messaging_event)
          end
        end
      end
    end

    halt 200
  end

  post '/:token' do
    check_auth_token

    api = Telegram::Bot::Api.new(ENV['TELEGRAM_TOKEN'])
    message = Telegram::Bot::Types::Update.new(@request_payload).message
    store_command_in_session(message)

    case message.text
    when /\/ajuda/, /\/start/
      text = <<-EOS
      E agora, quem poderá nos defender?
      Seguinte, é bem simples, tu envia /cidades.
      Depois escolhe o estado que quer mostrar as cidades.
      Aí vai aparecer uma linda lista com o 'nome da cidade: o comando'.
      Ex: Araçatuba: /aracatuba
      Daí tu manda o comando com o nome da cidade. (Calma que tá acabando)
      Depois vai aparecer a lista com os filmes que estão passando nessa cidade, aí é só escolher um e ser feliz
      EOS
      api.sendMessage(chat_id: message.chat.id, text: text)
    when /\/estados/
      text = StatesSerializer.new(states).to_message
      api.sendMessage(chat_id: message.chat.id, text: text)
    when /\/cidades/
      keyboard = states.map(&:name)
      answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: keyboard, one_time_keyboard: true)
      text = 'Escolhe um estado aí, pfv'
      api.sendMessage(chat_id: message.chat.id, text: text, reply_markup: answers)
    else
      case
      when is_city?(message.text)
        keyboard = movies_for_city(message.text).map(&:name)
        answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: keyboard, one_time_keyboard: true)
        text = 'Boa jovem! Só escolher um filme agora'
        api.sendMessage(chat_id: message.chat.id, text: text, reply_markup: answers)
      when @last_command && is_city?(@last_command)
        sessions = sessions_for_movie(message.text, @last_command)
        text = SessionsSerializer.new(sessions).to_message
        api.sendMessage(chat_id: message.chat.id, text: text)
        @session.del(message.from.id.to_s)
      when @last_command && @last_command.match(/\/cidades/)
        text = CitiesSerializer.new(cities_for_state(message.text)).to_message
        api.sendMessage(chat_id: message.chat.id, text: text)
        @session.del(message.from.id.to_s)
      else
        api.sendMessage(chat_id: message.chat.id, text: 'vish!')
      end
    end

    { success: true }.to_json # Telegram needs an body response, otherwise it will resend the message
  end

  def states
    settings.cache.fetch(states_cache_key) do
      crawler = Crawler.new(nil)
      crawler.states.map do |state|
        cities = state.last.map do |city|
          City.new(city['Nome'], city['ChaveUrl'])
        end
        State.new(state.first, cities)
      end
    end
  end

  def movies_for_city(city)
    settings.cache.fetch(movies_cache_key(city)) do
      crawler = Crawler.new(message_for_command(city))
      crawler.movies
    end
  end

  def sessions_for_movie(movie, city)
    settings.cache.fetch(sessions_cache_key(movie, city)) do
      movie = movies_for_city(city).find{ |m| m.name == movie }
      crawler = Crawler.new(message_for_command(city))
      crawler.sessions(movie)
    end
  end

  def cities_for_state(state)
    settings.cache.fetch(cities_cache_key(state)) do
      state = states.find{ |s| s.name == state }
      state.cities
    end
  end

  def received_message(event)
    sender_id = event['sender']['id']
    message = event['message']

    return unless message['text']

    city_permalink = parameterize(message['text'])
    city = states.map(&:cities).flatten.find{ |c| c.permalink == city_permalink }

    if city
      crawler = Crawler.new(city.permalink)
      movies = crawler.movies_with_image.first(10).map do |movie|
        {
          title: movie.name,
          image_url: movie.image,
          buttons: [{
            type: 'postback',
            title: 'Ver sessões',
            payload: "movie_id=#{movie.id}&city=#{city.permalink}"
          }]
        }
      end

      message_data = {
        attachment: {
          type: 'template',
          payload: {
            template_type: 'generic',
            elements: movies
          }
        }
      }
    else
      message_data = {
        text: 'Cidade não encontrada :/'
      }
    end

    FacebookMessenger.send_message(sender_id, message_data)
  end

  def received_postback(event)
    sender_id = event['sender']['id']
    postback = event['postback']
    parameters = postback['payload'].split('&')
    city = nil
    movie_id = nil

    parameters.each do |p|
      name, value = p.split('=')
      if name == 'movie_id' && value
        movie_id = value
      elsif name == 'city' && value
        city = value
      end
    end

    if city && movie_id
      movie = movies_for_city(city).find{ |m| m.id == movie_id }
      crawler = Crawler.new(city)
      sessions = crawler.sessions(movie).first(10).map do |session|
        {
          title: "#{session.cine.name} - #{session.time}",
          subtitle: "#{session.room} - #{session.type}"
        }
      end

      message_data = {
        attachment: {
          type: 'template',
          payload: {
            template_type: 'generic',
            elements: sessions
          }
        }
      }

      FacebookMessenger.send_message(sender_id, message_data)
    end
  end
end
