ENV['RACK_ENV'] = 'test'

require 'bundler'

Bundler.require(:test)

require File.expand_path('../../config/environment', __FILE__)
require 'rack/test'
require 'minitest/autorun'

def app
  CineminhaBot.new
end

class MiniTest::Test
  include Rack::Test::Methods
  include WebMock::API
  DatabaseCleaner.clean_with :truncation
  DatabaseCleaner.strategy = :truncation

  def before
    DatabaseCleaner.start
  end

  def after
    DatabaseCleaner.clean
  end

  def respond_with_file(file_name)
    file = File.open(File.expand_path("../support/#{ file_name }", __FILE__))
    response = file.read.to_s
    file.close
    response
  end
end