class State
  attr_accessor :name, :cities

  def initialize(name, cities)
    @name = name
    @cities = cities
  end

  def self.all
    file = File.open(File.expand_path('../../../config/states.json', __FILE__))
    states = JSON.parse(file.read).map do |state|
      cities = state.last.map do |city|
        City.new(city['Nome'], city['ChaveUrl'])
      end
      State.new(state.first, cities)
    end
    file.close
    states
  end
end