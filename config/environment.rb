require 'rubygems'
require 'bundler'
Bundler.require

require 'sinatra'
require 'sinatra/reloader'
require 'redis'
require 'redis-sinatra'
require 'rack/session/redis'
require 'telegram/bot'
require 'nokogiri'

Dir.glob(File.expand_path('../initializers/**/*.rb', __FILE__)).each { |f| require f }
Dir.glob(File.expand_path('../../lib/**/*.rb', __FILE__)).each { |f| require f }
Dir.glob(File.expand_path('../../app/**/*.rb', __FILE__)).each { |file| require file }