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

  get '/:token' do
    halt 403 unless Token.exists?(params[:token])
    token = ENV['TELEGRAM_TOKEN']

    Telegram::Bot::Client.run(token) do |bot|
      bot.listen do |message|
        p 'message', message

        if session[message.from.id]
          last_command = session[message.from.id][:last_command]
        else
          session[message.from.id] = { last_command: message.text } if message.text.match(/\//)
        end

        p 'session', session

        case message.text
        when /\/estados/
          states = State.all
          bot.api.sendMessage(chat_id: message.chat.id, text: states.map(&:name).join("\n"))
        when /\/cidades/
          answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: State.all.map(&:name), one_time_keyboard: true)
          bot.api.sendMessage(chat_id: message.chat.id, text: 'Escolhe um estado aí, pfv', reply_markup: answers)
        when /aracatuba/
          crawler = Crawler.new('aracatuba')
          answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: crawler.movies.map(&:name), one_time_keyboard: true)
          bot.api.sendMessage(chat_id: message.chat.id, text: crawler.movies.map(&:name).join("\n"), reply_markup: answers)
        else
          case last_command
          when /\/cidades/ then
            state = State.all.find{ |s| s.name == message.text }
            bot.api.sendMessage(chat_id: message.chat.id, text: state.cities.map(&:name).join("\n"))
          else
            bot.api.sendMessage(chat_id: message.chat.id, text: 'vish!')
          end
        end
      end
    end
  end
end