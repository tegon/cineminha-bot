class SessionsSerializer
  attr_accessor :sessions

  def initialize(sessions)
    @sessions = sessions
  end

  def type(session)
    # handle DUBLADO3DDUBLADO and DUBLADODUBLADO3D
    return session.type unless session.type.include?('DUBLADO')
    "DUBLADO#{session.type.gsub('DUBLADO', '')}"
  end

  def to_message
    sessions.map do |session|
      [
        "Horário: #{ session.time }",
        "#{ session.room }",
        "#{ session.cine.name } - #{ session.cine.location }",
        "#{ type(session) }"
      ].join("\n")
    end.join("\n \n")
  end

  def empty_message
    "Eita Giovana! Não achei sessões para esse filme :/"
  end
end
