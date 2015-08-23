class IngressoApp < Sinatra::Application
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
    def check_auth_token
      halt 403 unless Token.exists?(params[:token])
    end

    def set_session(message)
      @last_command = session[message.from.id][:last_command] if session[message.from.id]
      session[message.from.id] = { last_command: message.text } if is_command?(message.text)
    end

    def is_command?(text)
      text.match(/\//)
    end

    def is_city?(text)
      return unless is_command?(text)
      exists = false

      State.all.map do |state|
        city = state.cities.find{ |city| text == "/#{ city.permalink }" }
        exists = !city.nil?
        break if exists
      end

      exists
    end
  end

  get '/:token' do
    check_auth_token

    token = ENV['TELEGRAM_TOKEN']

    Telegram::Bot::Client.run(token) do |bot|
      bot.listen do |message|
        set_session(message)

        p 'message', message
        p 'session', session

        case message.text
        when /\/estados/
          states = State.all
          bot.api.sendMessage(chat_id: message.chat.id, text: states.map(&:name).join("\n"))
        when /\/cidades/
          answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: State.all.map(&:name), one_time_keyboard: true)
          bot.api.sendMessage(chat_id: message.chat.id, text: 'Escolhe um estado aí, pfv', reply_markup: answers)
        else
          case
          when is_city?(message.text)
            crawler = Crawler.new(message.text.gsub('/', ''))
            answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: crawler.movies.map(&:name), one_time_keyboard: true)
            bot.api.sendMessage(chat_id: message.chat.id, text: crawler.movies.map(&:name).join("\n"), reply_markup: answers)
          when @last_command && is_city?(@last_command)
            crawler = Crawler.new(@last_command.gsub('/', ''))
            movie = crawler.movies.find{ |m| m.name == message.text }
            sessions = crawler.sessions(movie)
            text = sessions.map do |session|
              "Horário: #{ session.time }\n Sala: #{ session.room }\n Cinema: #{ session.cine.name }\n Tipo: #{ session.type }"
            end
            bot.api.sendMessage(chat_id: message.chat.id, text: text.join("\n"))
          when @last_command && @last_command.match(/\/cidades/)
            state = State.all.find{ |s| s.name == message.text }
            text = state.cities.map do |city|
              "#{ city.name }: /#{ city.permalink }"
            end

            bot.api.sendMessage(chat_id: message.chat.id, text: text.join("\n \n"))
            session[message.from.id] = nil
          else
            bot.api.sendMessage(chat_id: message.chat.id, text: 'vish!')
          end
        end
      end
    end
  end
end