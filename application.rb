class CineminhaBot < Sinatra::Application
  register Sinatra::Cache
  use Rack::Session::Redis

  configure :development do
    register Sinatra::Reloader
    also_reload 'app/**/*.rb'
    also_reload 'lib/**/*.rb'
  end

  before do
    content_type :json
  end

  helpers do
    include ApplicationHelper
    include CacheHelper
    include SessionHelper
  end

  get '/:token' do
    check_auth_token

    Telegram::Bot::Client.run(ENV['TELEGRAM_TOKEN']) do |bot|
      bot.listen do |message|
        set_session(message)

        case message.text
        when /\/estados/
          text = StatesSerializer.new(states).to_message
          bot.api.sendMessage(chat_id: message.chat.id, text: text)
        when /\/cidades/
          keyboard = states.map(&:name)
          answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: keyboard, one_time_keyboard: true)
          text = 'Escolhe um estado aí, pfv'
          bot.api.sendMessage(chat_id: message.chat.id, text: text, reply_markup: answers)
        else
          case
          when is_city?(message.text)
            keyboard = movies_for_city(message.text).map(&:name)
            answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: keyboard, one_time_keyboard: true)
            text = 'Aí garoto! Só escolher um filme agora'
            bot.api.sendMessage(chat_id: message.chat.id, text: text, reply_markup: answers)
          when @last_command && is_city?(@last_command)
            sessions = sessions_for_movie(message.text, @last_command)
            text = SessionsSerializer.new(sessions).to_message
            bot.api.sendMessage(chat_id: message.chat.id, text: text)
          when @last_command && @last_command.match(/\/cidades/)
            text = CitiesSerializer.new(cities_for_state(message.text)).to_message
            bot.api.sendMessage(chat_id: message.chat.id, text: text)
            session[message.from.id] = nil
          else
            bot.api.sendMessage(chat_id: message.chat.id, text: 'vish!')
          end
        end
      end
    end
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