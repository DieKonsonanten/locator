require "lib/version"
require 'sinatra/base'
require "sinatra/config_file"
require 'yaml'
require 'yaml/store'
require 'bcrypt'
require 'pony'
require 'pp'

# This class is the Base Class of the locator.
# @example Star the application
#  Locator.run!
class Locator < Sinatra::Base
  register Sinatra::ConfigFile
  config_file '/Users/d0233972/.locator_config.yml'
  set :bind, '0.0.0.0'
# gives hash    pp settings.email
# gives value    pp settings.email[:user]

  enable :sessions
  set :root, File.dirname(__FILE__)

  # global vars
  def initialize

    super()
    @MAX_VOTES_REACHED_CODE=900
    @UID_ALREADY_TAKEN_CODE=901
    @OK_CODE=200

  end

  register do
    def auth (type)
      condition do
        redirect "/login" unless send("login?")
      end
    end
  end

  
  begin
    userTable = YAML.load_file('users.yml')
    puts "use existing user table"
  rescue Errno::ENOENT
    puts "creating new user table"
    userTable = {}
    @store_user = YAML::Store.new 'users.yml'
  end

  begin
    VotingTable = YAML.load_file('votes.yml')
    puts "use existing voting table"
  rescue Errno::ENOENT
    puts "creating new voting table"
    VotingTable = {}
    @store_votes = YAML::Store.new 'votes.yml'
  end

## Helpers
  helpers do
    def login?
      if session[:email].nil?
        return false
      else
        return true
      end
    end

    def name
      return session[:name]
    end

    def admin?
      return session[:admin]
    end

    def admin_mails?
      admin_mails = []
      allUsers = YAML.load_file('users.yml')
      allUsers.each do |email, values|
        values.each do |key, value|
          if key.to_s == 'admin' && value == true
            email = email
            admin_mails.push(email)
          end
        end
      end
      return admin_mails
    end

    def activated?
      not_activated = []
      allUsers = YAML.load_file('users.yml')
      allUsers.each do |email, values|
        values.each do |key, value|
          if key.to_s == 'enable' && value == false
            not_activated.push(email)
          end
        end
      end
      return not_activated
    end

    def to_boolean(str)
      str == 'true'
    end

    def getCheckedActivity(str)
      allVotes = YAML.load_file('votes.yml')
      if allVotes[str]['votes'].include? name
        return "checked"
      else
        return ""
      end
    end

    def getCheckedLocation(location, activity)
      allVotes = YAML.load_file('votes.yml')
      VotingTable[activity]['location'].each do |list|
        if list.has_key? (location)
          index = VotingTable[activity]['location'].index(list)
          if allVotes[activity]['location'][index][location]['votes'].include? name
            return "checked"
          else
            return ""
          end
        end
      end
    end

    def getVotedActivities
      counter = 0
      VotingTable.each do |activity, attributes|
        if VotingTable[activity]['votes'].include? name
            counter += 1
        end
      end
      return counter
    end
  end

### Default Redirect
  get '/', :auth => :user do 
    redirect "/login"
  end

### not logged in
  get '/login' do
    @title = 'Herzlich Willkommen liebe Konsonanten!'
    erb :index
  end

  post "/login" do
    if userTable.has_key?(params[:email])
      if userTable[params[:email]][:enable]
        user = userTable[params[:email]]
        if user[:passwordhash] == BCrypt::Engine.hash_secret(params[:password], user[:salt])
          session[:email] = params[:email]
          session[:name] = userTable[params[:email]][:name]
          session[:admin] = userTable[params[:email]][:admin]
          redirect "/voting"
        else
          # wrong password?
          @message = 'Falscher User und/oder falsches Passwort.'
          redirect '/login'
          pp "1"
        end
      else
        # user not activated
        @message = 'Dein User ist noch nicht freigeschaltet. Bitte wende dich an einen Admin.'
      end
    else
      # wrong username
      @message = 'Falscher User und/oder falsches Passwort.'
      pp "2"
    end
  end

  get "/signup" do
    @title = 'Registrierung!'
    erb :signup
  end

  post "/signup" do
    pStatus = @OK_CODE
    if not userTable[params[:email]]
      password_salt = BCrypt::Engine.generate_salt
      password_hash = BCrypt::Engine.hash_secret(params[:password], password_salt)

      #ideally this would be saved into a database, hash used just for sample
      userTable[params[:email]] = {
        :name => params[:name],
        :salt => password_salt,
        :passwordhash => password_hash,
        :enable => false,
        :admin => false
      }
      File.write('users.yml', userTable.to_yaml)
      # Pony.mail :to => admin_mails?,
      #   :from => "noreply@konsonanten.de",
      #   :subject => "Freigabe neuer Konsonant: #{params[:name]}!",
      #   :html_body => erb(:to_activate, layout: false),
      #   :via => :smtp,
      #   :via_options => {
      #     :address        => settings.email[:address],
      #     :port           => settings.email[:port],
      #     :enable_starttls_auto => true,
      #     :user_name      => settings.email[:user_name],
      #     :password       => settings.email[:password],
      #     :authentication => :plain, # :plain, :login, :cram_md5, no auth by default
      #     :domain         => "localhost.localdomain" # the HELO domain provided by the client to the server
      #   }
      #redirect "/login"
    else
        # username already used
        pStatus = @UID_ALREADY_TAKEN_CODE
    end
    status pStatus
  end

### logged in user interaction
  get '/voting', :auth => :user do
      @title = 'Hallo ' + name + '. Bitte stimme ab!'
      erb :voting
  end

  post '/cast_activity', :auth => :user do
    pStatus = @OK_CODE
    vote  = params['vote']
    isChecked = to_boolean(params['isChecked'])
    if isChecked
      if getVotedActivities >= 3
        pStatus=@MAX_VOTES_REACHED_CODE
      else
        VotingTable[vote]["votes"].push(name)
      end
    else
      VotingTable[vote]["votes"].delete(name)
    end
    File.write('votes.yml', VotingTable.to_yaml)
    status pStatus
  end

  post '/cast_location', :auth => :user do
    pStatus = @OK_CODE
    location  = params['loc']
    activity  = params['activity']
    isChecked = to_boolean(params['isChecked'])
    index = ''
    if isChecked
      VotingTable[activity]['location'].each do |item|
        item.values[0]['votes'].delete(name)
      end
      VotingTable[activity]['location'].each do |list|
          if list.has_key? (location)
            index = VotingTable[activity]['location'].index(list)
          end
        end
      VotingTable[activity]['location'][index][location]['votes'].push(name)
    end
    File.write('votes.yml', VotingTable.to_yaml)
    status pStatus
  end

  get '/results', :auth => :user do
    @title = 'Ergebnisse'
    erb :results
  end

  get '/profile', :auth => :user do
    @title = 'Dein Profil'
    erb :profile
  end

  get "/logout" do
    session[:name] = nil
    redirect "/"
  end

  get '/new_activity', :auth => :user do
    erb :new_activity
  end

  post '/new_activity', :auth => :user do
    @params = params
    location = []
    @params.each do |name, value|
      if name.match('location')
        instance = name.slice(8)
        url = 'url' + instance
        loc = {
          params[name] => {
          "votes" => [],
          "url" => params[url] }
          }
        location.push(loc)
        location.sort_by! { |h| h.first.first.downcase }
      end
    end

    VotingTable[params['activity']] = {
      "desc" => params['desc'],
      "votes" => [],
      "location" => location
    }
    File.write('votes.yml', Hash[VotingTable.sort_by { |x| x.first.downcase }].to_yaml)
    redirect '/voting'
  end

  get '/new_location', :auth => :user do
    erb :new_location
  end

  post '/new_location', :auth => :user do
    loc = {
      params[:location] => {
        "votes" => [],
        "url" => params[:url]
      }
    }

    VotingTable[params[:activity]]['location'].push(loc)
    VotingTable[params[:activity]]['location'].sort_by! { |h| h.first.first.downcase }
    File.write('votes.yml', VotingTable.to_yaml)
    redirect '/voting'
  end

### admin user interaction
  get '/activate', :auth => :user do
    if admin?
      @title = 'Hallo '
      erb :activate
    else
      redirect "/voting"
    end
  end

  post "/activate", :auth => :user do
    userTable[params[:user]][:enable] = true
    File.write('users.yml', userTable.to_yaml)
    if userTable[params[:user]][:enable] = true
      Pony.mail :to => userTable[params[:user]][:email],
        :from => "noreply@konsonanten.de",
        :subject => "Dein Account wurde aktiviert!",
        :html_body => erb(:activated, layout: false),
        :via => :smtp,
        :via_options => {
          :address        => settings.email[:address],
          :port           => settings.email[:port],
          :enable_starttls_auto => true,
          :user_name      => settings.email[:user_name],
          :password       => settings.email[:password],
          :authentication => :plain, # :plain, :login, :cram_md5, no auth by default
          :domain         => "localhost.localdomain" # the HELO domain provided by the client to the server
        }
      @title = 'Hallo ' + name + '.'
      @message = 'Die Aktivierung war erfolgreich.'
      erb :layout
    else
      if admin?
        @title = 'Hallo ' + name + '.'
        @message = 'Die Aktivierung war nicht erfolgreich!'
        erb :activate
      else
        redirect "/voting"
      end
    end
  end
end
