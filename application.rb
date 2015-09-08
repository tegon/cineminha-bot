class CineminhaBot < Sinatra::Application
  options = { host: ENV['OPENSHIFT_REDIS_HOST'], port: ENV['OPENSHIFT_REDIS_PORT'], password: ENV['REDIS_PASSWORD'] }

  set :cache, Sinatra::Cache::RedisStore.new(options)
  use Rack::Session::Redis, redis_server: options

  configure :development do
    register Sinatra::Reloader
    also_reload 'app/**/*.rb'
    also_reload 'lib/**/*.rb'
  end

  before do
    content_type :json
    request.body.rewind
    @request_payload = JSON.parse(request.body.read)
  end

  helpers do
    include ApplicationHelper
    include CacheHelper
    include SessionHelper
  end

  post '/:token' do
    api = Telegram::Bot::Api.new(ENV['TELEGRAM_TOKEN'])
    message = Telegram::Bot::Types::Update.new(@request_payload).message

    set_session(message)

    case message.text
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
      when @last_command && @last_command.match(/\/cidades/)
        text = CitiesSerializer.new(cities_for_state(message.text)).to_message
        api.sendMessage(chat_id: message.chat.id, text: text)
        session[message.from.id] = nil
      else
        api.sendMessage(chat_id: message.chat.id, text: 'vish!')
      end
    end
    {}.to_json
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