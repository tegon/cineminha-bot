class CitiesSerializer
  attr_accessor :cities

  def initialize(cities)
    @cities = cities
  end

  def to_message
    cities.map do |city|
      "#{ city.name }: /#{ city.permalink }"
    end.join("\n \n")
  end
end