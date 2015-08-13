class IngressoApp < Sinatra::Application
  register Sinatra::Cache

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
    token = '96408323:AAEDAFBXYvKGBmUsyx8H1h_ucWHNLkJVLL0'

    Telegram::Bot::Client.run(token) do |bot|
      bot.listen do |message|
        p message
        case message.text
        when /\/estado/
          states = State.all
          bot.api.sendMessage(chat_id: message.chat.id, text: states.map(&:name).join("\n"))
        when /\/cidades/
          cities = State.all.map(&:cities).flatten
          bot.api.sendMessage(chat_id: message.chat.id, text: cities.map(&:name).join("\n"))
        when /aracatuba/
          crawler = Crawler.new('aracatuba')
          answers = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: crawler.movies.map(&:name), one_time_keyboard: true)
          bot.api.sendMessage(chat_id: message.chat.id, text: crawler.movies.map(&:name).join("\n"), reply_markup: answers)
        else
          bot.api.sendMessage(chat_id: message.chat.id, text: 'vish!')
        end
      end
    end
  end
end