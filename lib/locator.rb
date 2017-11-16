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
# gives hash    pp settings.email
# gives value    pp settings.email[:user]

  enable :sessions
  set :root, File.dirname(__FILE__) 
# global vars
def initialize
  
  super()
  @MAX_VOTES_REACHED_CODE=900
  @OK_CODE=200
  
end
#


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
      if session[:name].nil?
        return false
      else
        return true
      end
    end

    def name
      return session[:name]
    end

    def admin?
      userTable = YAML.load_file('users.yml')
      return userTable[name][:admin]
    end

    def admin_mails?
      admin_mails = []
      allUsers = YAML.load_file('users.yml')
      allUsers.each do |name, values|
        values.each do |desc, value|
          if desc.to_s == 'admin' && value == true
            email = allUsers[name][:email]
            admin_mails.push(email)
          end
        end
      end
      return admin_mails
    end

    def activated?
      not_activated = []
      allUsers = YAML.load_file('users.yml')
      allUsers.each do |name, values|
        values.each do |desc, value|
          if desc.to_s == 'enable' && value == false
            not_activated.push(name)
          end
        end
      end
      return not_activated
    end
    
    def to_boolean(str)
      str == 'true'
    end
    
    def getCheckedStatus(str)
      allVotes = YAML.load_file('votes.yml')
      if allVotes[str]['votes'].include? name
        return "checked"
      else
        return ""
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
  get '/' do
    redirect "/login"
  end

### not logged in
  get '/login' do
    @title = 'Herzlich Willkommen liebe Konsonanten!'
    erb :index
  end

  post "/login" do
    if userTable.has_key?(params[:name])
      if userTable[params[:name]][:enable]
        user = userTable[params[:name]]
        if user[:passwordhash] == BCrypt::Engine.hash_secret(params[:password], user[:salt])
          session[:name] = params[:name]
          redirect "/voting"
        else
          # wrong password?
          redirect "/login"
        end
      else
        # user not activated
        @title = 'Herzlich Willkommen liebe Konsonanten!'
        @message = 'Dein User ist noch nicht freigeschaltet. Bitte wende dich an einen Admin.'
        erb :index
      end
    else
      @title = 'Registrierung!'
      @message = 'Dieser Username existiert nicht. Bitte registriere dich zuerst.'
      erb :signup
    end
  end

  get "/signup" do
    @title = 'Registrierung!'
    erb :signup
  end

  post "/signup" do
    if not userTable[params[:name]]
      password_salt = BCrypt::Engine.generate_salt
      password_hash = BCrypt::Engine.hash_secret(params[:password], password_salt)

      #ideally this would be saved into a database, hash used just for sample
      userTable[params[:name]] = {
        :email => params[:email],
        :salt => password_salt,
        :passwordhash => password_hash,
        :enable => false,
        :admin => false
      }
      File.write('users.yml', userTable.to_yaml)
      Pony.mail :to => admin_mails?,
        :from => "noreply@konsonanten.de",
        :subject => "Freigabe neuer Konsonant: #{params[:name]}!",
        :html_body => erb(:to_activate, layout: false),
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
      redirect "/login"
    else
        # username already used 
        @title = 'Registrierung!'
        @message = "Dieser Username ist bereits vergeben. Bitte verwende einen anderen Namen."
        erb :signup
    end
  end

### logged in user interaction
  get '/voting' do
    if login?
      @title = 'Hallo ' + name + '. Bitte stimme ab!'
      erb :voting
    else
      redirect "/login"
    end
  end

  post '/cast' do
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

  get '/results' do
    @title = 'Ergebnisse:'
    erb :results
  end

  get '/profile' do
    @title = 'Dein Profil'
    erb :profile
  end

  get "/logout" do
    session[:name] = nil
    redirect "/"
  end

  get '/new_activity' do
    erb :new_activity
  end

  post '/new_activity' do
    # params[:items].each do |id, value|
    #   pp id
    #   pp value
  # end
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
    end
  end
  
    VotingTable[params['activity']] = {
      "desc" => params['desc'],
      "votes" => [],
      "location" => location
    }
    File.write('votes.yml', VotingTable.to_yaml)
    redirect '/voting'
  end
### admin user interaction
  get '/activate' do
    if login? && admin?
      @title = 'Hallo '
      erb :activate
    else
      redirect "/voting"
    end
  end

  post "/activate" do
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
      if login? && admin?
        @title = 'Hallo ' + name + '.'
        @message = 'Die Aktivierung war nicht erfolgreich!'
        erb :activate
      else
        redirect "/voting"
      end
    end
  end
end
