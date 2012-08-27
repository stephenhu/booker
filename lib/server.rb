require "base64"
require "haml"
require "mysql"
require "active_record"
require "openssl"
require "sinatra"
require "sinatra/cookies"
require "yajl"

Dir.glob("./models/*").each { |r| require r }

@config =
  YAML.load_file('/home/hu/projects/booker/config/database.yml')['development']

ActiveRecord::Base.establish_connection @config

helpers do

  def check_auth
    return request.cookies["booker"]
  end

  def authenticate(email)

    u = User.find_by_email(email)
    cipher = OpenSSL::Cipher::AES.new( 128, :CBC )
    cipher.encrypt

    key = cipher.random_key
    iv  = cipher.random_iv

    token = cipher.update(email) + cipher.final
    
    return Base64.encode64(token)

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


# REST endpoints

post "/rest/authenticate" do
  token = authenticate(params[:email])
  response.set_cookie( "booker", :value => token, :path => '/',
    :expires => Time.now + (60*60*24*30) )
  return Yajl::Encoder.encode(token)
end

get "/rest/checktoken/:token" do

  puts params[:token]

end

post "/rest/reservations" do

 puts params[:uuid]
 puts params[:userid]
 puts params[:duration]
 puts params[:start]
 puts params[:details]
 puts params[:title]
 
end

