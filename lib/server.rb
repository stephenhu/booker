require "base64"
require "haml"
require "mysql"
require "active_record"
require "openssl"
require "sinatra"
require "sinatra/cookies"
require "yajl"

Dir.glob("./models/*").each { |r| require r }

config =
  YAML.load_file('/home/hu/projects/booker/config/database.yml')['development']

ActiveRecord::Base.establish_connection config

key = "1234567890000qwertyasdflkjzxcvnabcde88888888888888888888888888888a"
iv  = "blahblahblahpasswordpasswordsecret"

helpers do

  def check_auth
    return request.cookies["booker"]
  end

  def register(email)
    User.create(:email => email)
  end

  def authenticate(email)

    u = User.find_by_email(email)

    if u.nil?
      u = register(email)
    end

    #cipher = OpenSSL::Cipher.new("bf")
    #cipher.encrypt

    #token = cipher.update(email) + cipher.final
    
    return Base64.encode64(email)

  end

  def extract_user(token)
    
    #decipher = OpenSSL::Cipher.new("bf")
    #decipher.decrypt

    #email = decipher.update(Base64.decode64(token)) + decipher.final

    return User.find_by_email(Base64.decode64(token))
   
  end

  def get_start( d, start )
    return Date.strptime( d, "%m/%d/%Y" ).to_time + start.to_f * 3600
  end

  def get_end( start, duration )
    return start + duration.to_f * 60
  end

end

get "/" do

  @rooms = Room.all

  haml :index, :locals => { :rooms => @rooms }
 
end

get "/floors/?.?:floorid?" do

  case params[:floorid]
  when nil
    haml :floor10
  when "10"
    haml :floor10
  when "11"
    haml :floor11
  else
    haml :error, :locals => { :msg => "Floor Does Not Exist" }
  end

end

get "/rooms/?.?:roomid?" do

  case params[:roomid]
  when nil
    @rooms = Room.all
    haml :roomsall, :locals => { :rooms => @rooms }
  else
    @room = Room.where( 'id' => params[:roomid].to_i ).first
    if @room.nil?
      haml :error, :locals => { :msg => "Room Does Not Exist" }
    else
      haml :rooms, :locals => { :room => @room }
    end
  end

end

get "/reservations/?.?:roomid?" do

  @rooms = Room.all
    
  haml :reservations, :locals => { :rooms => @rooms, :id => params[:roomid] }

end

get "/tags/:tagname" do

  @ts = Room.joins(:tags).where('tags.tag' => params[:tagname])
  haml :tags, :locals => { :tag => params[:tagname], :tags => @ts }

end

get "/users/:name" do

  @user = User.where(:canonical => params[:name]).first

  #TODO: check null
  haml :users, :locals => { :user => @user } 

end

get "/about" do

  haml :about

end

# REST endpoints

#post "/rest/authenticate" do
  #token = authenticate(params[:email])
  #response.set_cookie( "booker", :value => token, :path => '/',
  #  :expires => Time.now + (60*60*24*30) )
  #return Yajl::Encoder.encode(token)
#end

#get "/rest/checktoken/:token" do
#  puts params[:token]
#end

post "/rest/reservations" do

  if params[:email].empty?
    token = request.cookies["booker"]
  else

    # not authenticated
    token = authenticate(params[:email])
    puts token
    response.set_cookie( "booker", :value => token, :path => "/",
      :expires => Time.now + (60*60*24*30) )

  end
  
  user = extract_user(token)

  enddate = params[:end]

  if params[:recurring] != 1
    enddate = params[:start]
  end

  s = get_start( params[:start], params[:time] )
  e = get_end( s, params[:duration] )
  puts "#{s} - #{e}"
  Reservation.create( :user_id => user.id,
                      :room_id => params[:roomid],
                      :title => params[:title],
                      :details => params[:details],
                      :start => s,
                      :end => e,
                      :recurring => params[:recurring] )
 
end

