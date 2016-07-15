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
  end

  get '/messenger-webhook' do
    if params['hub.mode'] === 'subscribe' && params['hub.verify_token'] === ENV['MESSENGER_TOKEN']
      params['hub.challenge']
    else
      halt 403
    end
  end

  post '/messenger-webhook' do
    p '=====================', @request_payload

    if @request_payload['object'] == 'page'
      @request_payload['entry'].each do |page_entry|
        pageID = page_entry['id']
        time_of_event = page_entry['time']

        page_entry['messaging'].each do |messaging_event|
          case
          when messaging_event['message']
            senderID = messaging_event['sender']['id']
            message = messaging_event['message']

            case message['text']
            when '/ajuda'
              text = 'Para começar, envie /cidades'

              message_data = {
                recipient: {
                  id: senderID
                },
                message: {
                  text: text
                }
              }

              FacebookMessenger.send_message(message_data)
            when '/cidades'
              buttons = states.map do |state|
                { type: 'postback', title: state.name, payload: state.name }
              end

              message_data = {
                recipient: {
                  id: senderID
                },
                message: {
                  attachment: {
                    type: 'template',
                    payload: {
                      template_type: 'generic',
                      elements: [
                        {
                          title: 'Estados',
                          subtititle: 'Escolhe um estado aí, pfv',
                          buttons: buttons
                        }
                      ]
                    }
                  }
                }
              }
            end

          when messaging_event['postback']
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
end
