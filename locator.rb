#http://guides.railsgirls.com/sinatra-app
#http://localhost:4567/

require 'sinatra'
require 'yaml/store'

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
