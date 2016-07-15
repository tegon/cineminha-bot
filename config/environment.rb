require 'rubygems'
require 'bundler'
Bundler.require

require 'telegram/bot'
require 'active_support/inflector/transliterate.rb'

Dir.glob(File.expand_path('../initializers/**/*.rb', __FILE__)).each { |f| require f }
Dir.glob(File.expand_path('../../lib/**/*.rb', __FILE__)).each { |f| require f }
Dir.glob(File.expand_path('../../app/**/*.rb', __FILE__)).each { |file| require file }
