require "base64"
require "haml"
require "mysql"
require "active_record"
require "openssl"
require "sinatra"
require "sinatra/cookies"

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

  haml :floor10
 
end

get "/floors/floor11" do

  haml :floor11

end

get "/tags/:tagname" do

  @ts = Topic.joins(:tags).where('tags.tag' => params[:tagname])
  haml :tags, :locals => { :tag => params[:tagname], :tags => @ts }

end

get "/topics/:topicid" do

  @topic = Topic.joins(:tags).where('id' => params[:topicid]).first
  haml :topics, :locals => { :topic => @topic }

end

get "/users/:name" do

  @user = User.where(:canonical => params[:name]).first

  #TODO: check null
  haml :users, :locals => { :user => @user } 

end

get "/getcookie" do
  
  puts request.cookies["topics"]

end

get "/setcookie/:value" do
  response.set_cookie( "topics", params[:value] )
end

get "/test/:email" do

  u = User.new( :email => params[:email] )
  u.save

end

# REST endpoints

post "/rest/authenticate" do
  token = authenticate(params[:email])
  response.set_cookie( "topics", token )
end

get "/rest/checktoken/:token" do

  puts params[:token]

end

