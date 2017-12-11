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

    def mail_to_all_users
      all_mails = []
      allUsers = YAML.load_file('users.yml')
      allUsers.each do |email, values|
        all_mails.push(email)
      end
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
    @message = session[:message]
    @msg_type = session[:msg_type]
    session[:message] = ""
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
          session[:message] = 'Falscher User und/oder falsches Passwort.'
          session[:msg_type] = 'danger'
          redirect '/login'
        end
      else
        # user not activated
        session[:message]= 'Dein User ist noch nicht freigeschaltet. Bitte wende dich an einen Admin.'
        session[:msg_type] = 'info'
        redirect '/login'
      end
    else
      # wrong username
      session[:message] = "Falscher User und/oder falsches Passwort."
      session[:msg_type] = 'danger'
      redirect '/login'
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
      Pony.mail(:to => admin_mails?,
        :from => "noreply@diekonsonanten.de",
        :subject => "Freigabe neuer Konsonant: #{params[:name]}!",
        :html_body => erb(:to_activate, layout: false),
        :via => :sendmail)
      redirect "/login"
    else
        # username already used
        pStatus = @UID_ALREADY_TAKEN_CODE
    end
    status pStatus
  end

### logged in user interaction
  get '/voting', :auth => :user do
      @title = 'Hallo ' + name + '. Bitte stimme ab!'
      @message = session[:message]
      @msg_type = session[:msg_type]
      session[:message] = ""
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
    session.clear
    redirect "/"
  end

  get '/new_activity', :auth => :user do
    @message = session[:message]
    @msg_type = session[:msg_type]
    session[:message] = ""
    erb :new_activity
  end

  post '/new_activity', :auth => :user do
    if not VotingTable[params[:activity]]
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
      if VotingTable[params[:activity]]
      Pony.mail(:to => mail_to_all_users,
        :from => "noreply@diekonsonanten.de",
        :subject => "Eine neue Aktivität wurde hinzugefügt",
        :html_body => "<p> Hallo lieber Konsonant!</p>
               <p> " + name + " hat gerade die Aktivität " + params['activity'] + " hinzugefügt. Sofern du möchtest, kannst du deine Stimmen jetzt anpassen.</p>
               <p> Viel Spaß beim Abstimmen. <br>
               Die Konsonanten </p>")
      redirect '/voting'
      end
    else
      session[:message] = "Die Aktivität "+ params[:activity] +" ist bereits hinterlegt. <a href=/new_location?activity=" + params[:activity] + ">Eine neue Location hinzufügen</a>"
      session[:msg_type] = 'info'
      redirect back
    end
  end

  get '/new_location', :auth => :user do
    erb :new_location
  end

  post '/new_location', :auth => :user do
    found = 0
    VotingTable[params[:activity]]['location'].each do |locs|
      locs.each do |loc, values|
        if loc == params[:location]
          found += 1
          break
        end
      end
    end
    if found == 0
      location = {
        params[:location] => {
          "votes" => [],
          "url" => params[:url]
        }
      }

      VotingTable[params[:activity]]['location'].push(location)
      VotingTable[params[:activity]]['location'].sort_by! { |h| h.first.first.downcase }
      File.write('votes.yml', VotingTable.to_yaml)
    else
      session[:message] = "Der Ort " + params[:location] + " ist für " + params[:activity] + " bereits hinterlegt."
      session[:msg_type] = 'info'
    end
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
  
  post "/do_activity", :auth => :user do
    choosen_act = params[:do_activity]
    session[:message] = 'Die Aktivität ' + choosen_act + ' wurde für den nächsten Termin ausgewählt.'
    session[:msg_type] = 'success'
    VotingTable[choosen_act]['votes'].clear
    File.write('votes.yml', VotingTable.to_yaml)
    redirect "voting"
  end

  post "/delete_activity", :auth => :user do
    choosen_act = params[:delete_activity]
    Pony.mail(:to => admin_mails?,
      :from => "noreply@diekonsonanten.de",
      :subject => "Eine Aktivität soll gelöscht werden!",
      :html_body => "<p> Hallo Admins!</p>
             <p> Der User " + name + " möchte, dass die Aktivität '" + choosen_act + "'  gelöscht wird! </p>
             <p> Viele Grüße <br>
             Die Konsonanten </p>")
    session[:message] = 'Die Admins wurden per Mail informiert, dass die Aktivität "' + choosen_act + '" gelöscht werden soll.'
    session[:msg_type] = 'success'
    redirect "voting"
  end

  post "/activate", :auth => :user do
    userTable[params[:email]][:enable] = true
    File.write('users.yml', userTable.to_yaml)
    if userTable[params[:email]][:enable] = true
      Pony.mail(:to => params[:email],
        :from => "noreply@diekonsonanten.de",
        :subject => "Dein Account wurde aktiviert!",
        :html_body => "<p> Hallo "+ userTable[params[:email]][:name] +"!</p>
               <p> Dein Account wurde soeben aktiviert. </p>
               <p> Viel Spaß beim Abstimmen. <br>
               Die Konsonanten </p>")
      @title = 'Hallo ' + name + '.'
      @message = 'Die Aktivierung war erfolgreich.'
      @msg_type = 'success'
      erb :layout
    else
      if admin?
        @title = 'Hallo ' + name + '.'
        @message = 'Die Aktivierung war nicht erfolgreich!'
        @msg_type = 'danger'
        erb :activate
      else
        redirect "/voting"
      end
    end
  end
end
