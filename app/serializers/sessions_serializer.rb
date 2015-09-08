class SessionsSerializer
  attr_accessor :sessions

  def initialize(sessions)
    @sessions = sessions
  end

  def to_message
    sessions.map do |session|
      [
        "Horário: #{ session.time }",
        "#{ session.room }",
        "#{ session.cine.name } - #{ session.cine.location }",
        "#{ session.type }"
      ].join("\n")
    end.join("\n \n")
  end
end