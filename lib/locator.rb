require "lib/version"
require 'sinatra/base'
require 'yaml/store'

# This class is the Base Class of the locator.
# @example Star the application
#  Locator.run!
class Locator < Sinatra::Base

  set :root, File.dirname(__FILE__)

  Choices = {
    'KLE' => 'Klettern',
    'TRA' => 'Trampolin',
    'WAN' => 'Wanders',
    'FRE' => 'Freizeitpark',
  }

  get '/' do
    @title = 'Willkommen zum Voting für die nächste Unternehmung!'
    erb :index
  end

  post '/cast' do
    @title = 'Vielen Dank für deine Teilnahme!'
    @vote  = params['vote']
    @store = YAML::Store.new 'votes.yml'
    @store.transaction do
      @store['votes'] ||= {}
      @store['votes'][@vote] ||= 0
      @store['votes'][@vote] += 1
    end
    erb :cast
  end

  get '/results' do
    @title = 'Ergebnisse:'
    @store = YAML::Store.new 'votes.yml'
    @votes = @store.transaction { @store['votes'] }
    erb :results
  end
end
