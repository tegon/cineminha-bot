class Movie
  attr_accessor :name, :id, :sessions

  def initialize(name, id)
    @name = name
    @id = id
    @sessions = []
  end

  def to_json(options)
    attributes = {
      id: @id,
      name: @name,
      sessions: @sessions.to_json
    }.to_json
  end
end