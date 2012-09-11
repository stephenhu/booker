require "base64"
require "haml"
require "mysql"
require "active_record"
require "active_support/core_ext/time/calculations"
require "openssl"
require "sinatra"
require "sinatra/cookies"
require "yajl"

enable :logging

Dir.glob("./models/*").each { |r| require r }

config =
  YAML.load_file('/home/hu/projects/booker/config/database.yml')['development']

ActiveRecord::Base.establish_connection config

key = "1234567890000qwertyasdflkjzxcvnabcde88888888888888888888888888888a"
iv  = "blahblahblahpasswordpasswordsecret"

helpers do

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
    return start + duration.to_f * 3600
  end

  def check_conflict(meetings)

    meetings.each do |meeting|

      r = Reservation.where( 
        "room_id = :roomid AND ((start <= :start AND end > :start)" +
        " OR (start <= :end AND end > :end))",
        { :roomid => meeting[:roomid], :start => meeting[:start],
        :end => meeting[:end] } )

      if r.length > 0
        return true 
      end


    end

    return false

  end

  def get_recurring( roomid, frequency, s, e )

    meetings = Array.new

    case frequency.to_i                                                  
    when 0                                                                        
      hash = { :roomid => roomid, :start => s, :end => e }               
      meetings.push hash                                                          
    when 1                                                                        
# calculate 3 months of weekly                                              
      s2 = s                                                                      
      e2 = e                                                                      
      12.times do |i|                                                             
        hash = { :roomid => roomid, :start => s2, :end => e2 }           
        s2 = s2 + 7 * 60 * 60 * 24                                                
        e2 = e2 + 7 * 60 * 60 * 24                                                
        meetings.push hash                                                        
      end                                                                         
    when 2                                                                        
      s4 = s                                                                      
      e4 = e                                                                      
# calculate 3 months of bi-weekly                                           
      6.times do |i|                                                              
        hash = { :roomid => roomid, :start => s4, :end => e4 }           
        s4 = s4 + 14 * 60 * 60 * 24                                               
        e4 = e4 + 14 * 60 * 60 * 24                                               
        meetings.push hash                                                        
      end                                                                         
    when 3                                                                        
# calculate 3 months of monthly                                             
      s8 = s                                                                      
      e8 = e                                                                      
      3.times do |i|                                                              
        hash = { :roomid => roomid, :start => s8, :end => e8 }           
        s8 = s8 + 28 * 60 * 60 * 24                                               
        e8 = e8 + 28 * 60 * 60 * 24                                               
        meetings.push hash                                                        
      end                                                                         
    end

    return meetings

  end

  def get_multi_day( roomid, s, e )
    
    meetings = Array.new

    end_date = Date.strptime( e, "%m/%d/%Y" )
    delta = (end_date - s.to_date + 1).to_i
 
    delta.times do |day|
      start_time = s + day * 60 * 60 * 24
      end_date = start_time.to_date
      end_time   = end_date.to_time + 18 * 60 * 60 
      puts "day = #{day} start = #{start_time} end = #{end_time} wday = #{end_date.wday}"
      if !end_date.saturday? and !end_date.sunday?
        hash = { :roomid => roomid, :start => start_time, :end => end_time }
        puts hash
        meetings.push hash
      end
    end

    return meetings

  end
 
  def reserve( userid, title, details, recurring, meetings ) 

    meetings.each do |meeting|

      Reservation.create( :user_id => userid,                                    
                          :room_id => meeting[:roomid],                            
                          :title => title,                               
                          :details => details,                           
                          :start => meeting[:start],                                            
                          :end => meeting[:end],                                              
                          :recurring => recurring )

    end

  end

  def init_schedule( hour_start, hour_end )

    schedule = Hash.new

    for i in hour_start ... hour_end

      top = { :organizer => "",
        :title => "",
        :start => "#{i}:00",
        :end   => "#{i}:30",
        :recurring => "",
        :open => true }

      bottom = { :organizer => "",
        :title => "",
        :start => "#{i}:30",
        :end   => "#{i+1}:00",
        :recurring => "",
        :open => true }

      schedule[i.to_f]       = top
      schedule[i.to_f+0.5]   = bottom
    
    end

    return schedule

  end

  def get_schedule(roomid)

    @book = Reservation.where(
      "room_id = :roomid AND start >= :s AND end <= :e",
      { :roomid => params[:roomid].to_i, :s => Time.now.beginning_of_day,
      :e => Time.now.end_of_day } ).all

    rec = [ "no", "weekly", "bi-weekly", "monthly" ]

    schedule = init_schedule( 7, 19 )

    @book.each do |b|

      slots = (b.end.hour - b.start.hour) * 2
      index = b.start.hour.to_f

      if b.start.min == 30
        slots -= 1
        index = b.start.hour.to_f + 0.5
      end

      if b.start.min == 30
        slots += 1
      end

      schedule[index][:title]     = b.title
      schedule[index][:organizer] = b.user_id
      schedule[index][:recurring] = rec[b.recurring]
      schedule[index][:open]      = false

      for i in 0 ... slots
        schedule[index+i.to_f*0.5][:open] = false
      end

    end

    return schedule 

  end

  def x_to_f(x)

    if x

      t = Time.parse(x)

      result = t.hour.to_f

      if t.min == 30
        result += 0.5
      end

    else
      result = 0.0
    end

    return result

  end

  def get_duration( s, e )

    return x_to_f(e) - x_to_f(s)

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

    @book = get_schedule(params[:roomid])
 
    if @room.nil?
      haml :error, :locals => { :msg => "Room Does Not Exist" }
    else
      haml :rooms, :locals => { :room => @room, :book => @book }
    end
  end

end

get "/reservations/?.?:roomid?" do

  @rooms = Room.all
    
  haml :reservations, :locals => { :rooms => @rooms,
    :id => params[:roomid], :s => x_to_f(params[:start]),
    :d => get_duration( params[:start], params[:end] ) }

end

get "/tags/:tagname" do

  @ts = Room.joins(:tags).where('tags.tag' => params[:tagname])
  haml :tags, :locals => { :tag => params[:tagname], :tags => @ts }

end

get "/users/?.?:id?" do

  if params[:id]

    @user = User.where( :id => params[:id] ).first

    if @user
      haml :users, :locals => { :user => @user } 
    else
      haml :error, :locals => { :msg => "User Not Found" }
    end

  else

    token = request.cookies["booker"]

    if token
      user = extract_user(token)
      haml :users, :locals => { :user => user }
    else
      # redirect to login page
    end

  end

end

get "/about" do

  haml :about

end

post "/rest/reservations" do

  logger.info "reservation request received"
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
  puts enddate

  if params[:recurring].to_i != 0 and params[:recurring].to_i != 4
    enddate = params[:start]
  end

  s = get_start( params[:start], params[:time] )
  e = get_end( s, params[:duration] )
  puts "#{s} - #{e}"

  if params[:recurring].to_i == 4 
    meetings = get_multi_day( params[:roomid], s, params[:end] )
  else
    meetings = get_recurring( params[:roomid], params[:recurring], s, e )
  end

  if check_conflict(meetings)
    return Yajl::Encoder.encode("6000, room conflict")
  else

    result = reserve( user.id, params[:title], params[:details],
      params[:recurring], meetings )

    #if result == 0
    #  return Yajl::Encoder.encode("0, success")
    #else
    #  return Yajl::Encoder.encode("5000, Internal Error")
    #end
    return Yajl::Encoder.encode("0, success")

  end

end

