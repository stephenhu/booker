require "action_mailer"
require "active_record"
require "active_support/core_ext/time/calculations"
require "base64"
require "digest/md5"
require "haml"
require "logger"
require "mysql"
require "openssl"
require "ri_cal"
require "sinatra"
require "sinatra/cookies"
require "yajl"

enable :logging

# logging
logger = Logger.new("booker.log")

Dir.glob("./models/*").each { |r| require r }

env = ENV["RACK_ENV"] || "development"

config =
 # YAML.load_file('/home/hu/projects/booker/config/database.yml')[env]
  YAML.load_file(File.join( Sinatra::Application.root,  "../config/database.yml" ) )[env]

ActiveRecord::Base.logger = Logger.new("db.log")
ActiveRecord::Base.establish_connection config

key = "1234567890000qwertyasdflkjzxcvnabcde88888888888888888888888888888a"
iv  = "blahblahblahpasswordpasswordsecret"


configure do

  set :root,     File.dirname(__FILE__)
  set :views,    File.join( Sinatra::Application.root, "views" )
  set :haml,     { :format => :html5 }

  ActionMailer::Base.smtp_settings = {

    :address => "smtp.vmware.com",
    :port    => "25",
    :domain  => "vmware.com"

  }

end

class Invite < ActionMailer::Base

  def generate_ics( reservation, invitees )

    stamp = Time.now

    cal = RiCal.Calendar do |cal|
      cal.event do |event|
        event.summary         = reservation.title
        event.description     = reservation.details
        event.dtstart         = reservation.start
        event.dtend           = reservation.end
        event.dtstamp         = stamp
        event.last_modified   = stamp
        event.organizer       = reservation.organizer_email.gsub( "+admin", "" )
        event.location        = reservation.room_name

        invitees.each do |invitee|
          event.add_attendee invitee
        end
        
      end
    end

  end

  def meeting_invite( reservation, recipients )

    recipients.push reservation.organizer_email.gsub( "+admin", "" )

    logger.info "the recipients #{recipients}"

    ics = generate_ics reservation, recipients

    logger.info ics.to_s

    @test = "big mac"
    #attachments["meeting.ics"] = { :content => ics.to_s,
    #  :mime_type => "text/calendar", :charset => "utf-8" }

    mail( :to => recipients, :subject => reservation.title,
      :template_name => "content",
      :from => reservation.organizer_email )
    
  end

end

helpers do

  def cancel_meeting( id, recurring )

    r = Reservation.find(id)

    if !r.nil?
      if recurring
        Reservation.destroy_all(:seriesid => r.seriesid)
      else
        Reservation.destroy(id)
      end
    end

  end

  def register( email, admin )
    User.create( :email => email, :admin => admin )
  end

  def check_token

    token = request.cookies["booker"]

    user = extract_user(token)

    if user.nil?
      @logged = false
    else
      @logged = true
    end

    return user

  end

  def authenticate( email, admin )

    u = User.find_by_email(email)

    if u.nil?
      u = register( email, admin )
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
    if token.nil?
      return nil
    else
      return User.find_by_email(Base64.decode64(token))
    end
 
  end

  def get_date_time( d, time_float )
    return Date.strptime( d, "%m/%d/%Y" ).to_time + time_float.to_f * 3600
  end

  def add_date_time( dtime, duration )
    return dtime + duration.to_f * 3600
  end

  def get_end_day(reservations)

    multi = Reservation.where(:seriesid => reservations[0].seriesid)

    if multi.nil?
      halt 503, "Multi-day logic error."
    else
      return multi[multi.length-1].end
    end

  end

  def join_rooms(roomid)

    case roomid
    when 1
      a = [ 1, 17, 18 ]
    when 2
      a = [ 2, 17, 18, 19 ]
    when 3
      a = [ 3, 17, 19 ]
    when 14
      a = [ 14, 20 ]
    when 15
      a = [ 15, 20 ]
    when 17
      a = [ 1, 2, 3, 17, 18, 19 ]
    when 18
      a = [ 1, 2, 17, 18, 19 ]
    when 19
      a = [ 2, 3, 17, 19 ]
    when 20
      a = [ 14, 15, 20 ]
    else
      a = [ roomid ]
    end

    return a

  end

  def check_recurring(r)

    if r == 3 or r == 4
      return false
    else
      return true
    end

  end

  def check_date(s)
    return s.to_date >= Date.today ? true : false
  end

  def check_conflict( meetings, reserveid )
    
    if !reserveid.nil?
      rsvps = get_reservations(reserveid)
    end
    
    meetings.each do |meeting|

      roomids = join_rooms(meeting[:roomid])

      if rsvps.nil?

        r = Reservation.where( 
          "room_id IN (:roomids) AND ((start <= :start AND end > :start)" +
          " OR (start <= :end AND end > :end))",
          { :roomids => roomids, :start => meeting[:start],
          :end => meeting[:end] } )

      else

        ids = rsvps.pluck(:id)

        r = Reservation.where(                                                  
          "room_id IN (:roomids) AND ((start <= :start AND end > :start)" +         
          " OR (start <= :end AND end > :end)) AND (id NOT IN (:rsvps))",          
          { :roomids => roomids, :start => meeting[:start],             
          :end => meeting[:end], :rsvps => ids } )
      
      end

      if r.length > 0
        return true
      end

    end

    return false

  end

  def merge_meetings( meetings, reservations )
    
    if meetings.length == reservations.length

      meetings.each_with_index do |meeting, i|

        meeting[:id] = reservations[i].id

      end

    end

    return meetings

  end

  def get_reservations(id)

    #r = Reservation.find(id) this only returns a single element
    r = Reservation.where(:id => id)
                                                        
    if r[0].seriesid != ""
                                     
      result = Reservation.where(:seriesid => r[0].seriesid).order("start ASC")
                                                                            
      return result

    else
      return r
    end
                                                    
  end

  def get_recurring( roomid, frequency, s, e )

    meetings = Array.new

    case frequency
    when 3                                                                        
      hash = { :roomid => roomid, :start => s, :end => e }               
      meetings.push hash                                                          
    when 0                                                                        
# calculate 3 months of weekly                                              
      s1 = s                                                                      
      e1 = e
      12.times do |i|                                                             
        hash = { :roomid => roomid, :start => s1, :end => e1 }           
        s1 = s1 + 7 * 60 * 60 * 24                                                
        e1 = e1 + 7 * 60 * 60 * 24                                                
        meetings.push hash                                                        
      end                                                                         
    when 1                                                                        
      s2 = s                                                                      
      e2 = e                                                                      
# calculate 3 months of bi-weekly                                           
      6.times do |i|                                                              
        hash = { :roomid => roomid, :start => s2, :end => e2 }           
        s2 = s2 + 14 * 60 * 60 * 24                                               
        e2 = e2 + 14 * 60 * 60 * 24                                               
        meetings.push hash                                                        
      end                                                                         
    when 2                                                                        
# calculate 3 months of monthly                                             
      s3 = s                                                                      
      e3 = e                                                                      
      3.times do |i|                                                              
        hash = { :roomid => roomid, :start => s3, :end => e3 }           
        s3 = s3 + 28 * 60 * 60 * 24                                               
        e3 = e3 + 28 * 60 * 60 * 24                                               
        meetings.push hash                                                        
      end                                                                         
    end

    return meetings

  end

  def get_multi_day( roomid, s, enddate, duration )
    
    meetings = Array.new
    
    delta = (Date.strptime( enddate, "%m/%d/%Y" ) - s.to_date + 1).to_i
    logger.info "enddate: #{enddate} start: #{s.to_date}"
    logger.info "delta is #{delta}" 
    delta.times do |day|

      start_time = s + day * 60 * 60 * 24
      end_time = start_time + duration.to_f * 3600 
      logger.info "day = #{day} start = #{start_time} end = #{end_time} wday = #{end_time.to_date.wday}"

      if !end_time.to_date.saturday? and !end_time.to_date.sunday?
        hash = { :roomid => roomid, :start => start_time, :end => end_time }
        meetings.push hash
      end

    end

    return meetings

  end

  def upgrade_reservations( reservations, meetings, old_recur, new_recur,
    roomid, title, details )

    t = [ 12, 6, 3 ]

    if old_recur == 3
      modulus = 0
    elsif old_recur == 4
      halt 503, "Multi-day reservation cannot be upgraded."
    else
      modulus = t[new_recur] / t[old_recur]
    end

    index = 0

    reservations.each_with_index do |r,i|

      r.room_id     = roomid
      r.title       = title
      r.details     = details
      r.recurring   = new_recur
      r.start       = meetings[index][:start]
      r.end         = meetings[index][:end]
      r.save

      index = index + modulus

    end

    uncreated = Array.new

    meetings.each_with_index do |m,j|

      if modulus != 0

        if j % modulus != 0
          uncreated.push m
        end

      else

        if j != 0
          uncreated.push m
        end

      end

    end

    reserve( reservations[0].user_id, title, details, new_recur, uncreated,
      reservations[0].seriesid, reservations[0].id )

    return

  end

  def downgrade_reservations( reservations, old_recur, new_recur, roomid,
    title, details )

    t = [ 12, 6, 3 ]

    if reservations.nil?
      halt 404, "Unable to find reservation(s)."
    end
    
    if new_recur == 3
      modulus = 0
    elsif new_recur == 4
      halt 503, "Cannot downgrade reservation to multi-day."
    else
      modulus = t[old_recur] / t[new_recur]
    end

    reservations.each_with_index do |r,i|

      if (modulus == 0 and i != 0) or (modulus != 0 and i % modulus != 0)
        r.destroy
      else
        r.room_id     = roomid
        r.title       = title
        r.details     = details
        r.recurring   = new_recur
        r.save
      end

    end

  end

  def change_multi_day_reservations( reservations, roomid, title, details,
    old_recur, new_recur, meetings, seriesid )

    reservations.each_with_index do |r,i|

      if i != 0
        r.destroy
      else
        r.room_id     = roomid
        r.title       = title
        r.details     = details
        r.recurring   = new_recur
        r.start       = meetings[0][:start]
        r.end         = meetings[0][:end]
        r.save
      end

    end

    meetings.delete_at(0)

    if old_recur == 4

       if check_recurring(new_recur) or new_recur == 4

         reserve( reservations[0].user_id, title, details, new_recur,
           meetings, seriesid, reservations[0].id )  

       end

    elsif new_recur == 4

      reserve( reservations[0].user_id, title, details, new_recur,
        meetings, seriesid, reservations[0].id )

    else
      halt 503, "Unable to make reservation."
    end

  end

  def modify_reservations( reserveid, roomid, title, details, recurring,
    meetings, seriesid )

    reservations = get_reservations(reserveid)

    reservations.each_with_index do |r,i|
      r.room_id   = roomid
      r.title     = title
      r.details   = details
      r.start     = meetings[i][:start]
      r.end       = meetings[i][:end]
      r.recurring = recurring
      r.seriesid  = seriesid
      r.save
    end

  end

  def reserve( userid, title, details, recurring, meetings, seriesid,
    originid=0 ) 

    rids     = Array.new
    
    meetings.each_with_index do |meeting,i|

      if i == 0 and originid == 0

        r = Reservation.create( :user_id => userid,                                    
                                :room_id => meeting[:roomid],                            
                                :title => title,                               
                                :details => details,                           
                                :start => meeting[:start],                                            
                                :end => meeting[:end],                                              
                                :recurring => recurring,
                                :seriesid => seriesid )

        originid = r.id

      else

        r = Reservation.create( :user_id => userid,
                                :room_id => meeting[:roomid],
                                :title => title,
                                :details => details,
                                :start => meeting[:start],
                                :end => meeting[:end],
                                :recurring => recurring,
                                :seriesid => seriesid,
                                :originid => originid )

      end

      rids.push r.id

    end

    return rids

  end

  def add_invitees( rids, invitees )

    # find invitees, if not found then add user

    uids       = Array.new
    recipients = Array.new

    emails = invitees.split ","

    emails.each do |e|

      e.strip!

      user = User.find_by_email(e)

      if user.nil?
        logger.info "#{e} user not found"
        if !e.index("emc.com").nil? or !e.index("mozy.com").nil? or
          !e.index("rbcon.com").nil? or !e.index("vmware.com").nil?
          u = User.create :email => e
          uids.push u.id
          recipients.push u.email
        else
          logger.error "invalid email domain"
        end

      else
        logger.info "#{e} user found"
        uids.push user.id
        recipients.push user.email
      end
    end

    rids.each do |rid|
      uids.each do |uid|
        Invitee.create :reservation_id => rid, :user_id => uid
      end 
    end  

    r = Reservation.find rids[0]

    logger.info "sending mail"
    email = Invite.meeting_invite r, recipients
    #email.deliver

  end

  def init_schedule( hour_start, hour_end )

    schedule = Hash.new

    for i in hour_start ... hour_end

      top = {
        :organizer => "",
        :title => "",
        :start => "#{i}:00",
        :end   => "#{i}:30",
        :recurring => "",
        :open => true }

      bottom = {
        :organizer => "",
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

    roomids = join_rooms(roomid)

    @book = Reservation.where(
      "room_id IN (:roomids) AND start >= :s AND end <= :e",
      { :roomids => roomids, :s => Time.now.beginning_of_day,
      :e => Time.now.end_of_day } ).all

    rec = [ "none", "weekly", "bi-weekly", "monthly" ]

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
      schedule[index][:organizer] = b.organizer_email
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

  def remove_meetings(rids)

    logger.info "rids legnth: #{rids.length}"
    logger.info "rids first id: #{rids[0]}"

    rids.each_with_index do |r,i|

      if i != 0
        logger.info "destory #{i}"
        Reservation.destroy(r)
        rids.delete_at(i)
      end

    end

  end

end

get "/" do

  @user = check_token

  if @user.nil? or @user.team_id != 5
    haml :floor10
  else
    haml :floor11
  end
 
end

get "/floors/?.?:floorid?" do

  @user = check_token

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

  @user = check_token

  case params[:roomid]
  when nil
    @rooms = Room.order(:floor).all
    haml :roomsall, :locals => { :rooms => @rooms }
  else
    @room = Room.where( 'id' => params[:roomid].to_i ).first

    @book = get_schedule(params[:roomid].to_i)
 
    if @room.nil?
      haml :error, :locals => { :msg => "Room Does Not Exist" }
    else
      haml :rooms, :locals => { :room => @room, :book => @book }
    end
  end

end

get "/reservations/?.?:reserveid?" do

  @user = check_token

  if @user.nil?
    redirect "/login"
  end

  @rooms = Room.all 

  if params[:update].nil?

    haml :reservations, :locals => { :rooms => @rooms,
      :id => params[:roomid], :s => x_to_f(params[:start]),
      :d => get_duration( params[:start], params[:end] ),
      :recurring => nil, :update => false, :reserveid => params[:reserveid] }

  else

    r = get_reservations(params[:reserveid].to_i)

    if r.nil?
      halt 404, "Reservation not found."
    else

      if r[0].recurring == 4
        mday_last = get_end_day(r)
        edate     = mday_last.strftime("%m/%d/%Y")
      else
        edate = r[0].end.strftime("%m/%d/%Y")
      end

    end

    haml :reservations, :locals => { :rooms => @rooms,
      :id => r[0].room_id, :s => x_to_f(r[0].start.strftime("%R")),
      :d => get_duration( r[0].start.strftime("%R"), r[0].end.strftime("%R") ),
      :title => r[0].title, :details => r[0].details, :recurring => r[0].recurring,
      :sdate => r[0].start.strftime("%m/%d/%Y"),
      :edate => edate,
#      :invitees => r.invitees_delimited,
      :update => true,
      :reserveid => params[:reserveid].to_i,
      :user_id => @user.id }

  end

end

get "/tags/?.?:tagname?" do

  @user = check_token

  if params[:tagname].nil?

    tags = Tag.all
    haml :tagsall, :locals => { :tags => tags }

  else

    @ts = Room.joins(:tags).where('tags.tag' => params[:tagname])
    haml :tags, :locals => { :tag => params[:tagname], :tags => @ts }

  end

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

    @user = check_token

    if @user.nil?
      haml :login 
    else
      haml :users, :locals => { :user => @user }
    end

  end

end

get "/login" do

  @user = check_token

  haml :login

end

get "/logout" do
  response.delete_cookie("booker")
  redirect "/"
end

get "/about" do

  @user = check_token
  haml :about

end

post "/rest/reservations" do

  logger.info "reservation request received"

  user = check_token

  roomid    = params[:roomid].to_i
  recur     = params[:recurring].to_i
  enddate   = params[:end]
  duration  = params[:duration]

  if recur != 3 and recur != 4
    enddate = params[:start]
  end

  s = get_date_time( params[:start], params[:time] )
  e = add_date_time( s, duration )

  logger.info "#{s} - #{e}"

  if !check_date(s)
    halt 409,
      "Cannot book meetings in the past."
  end

  if recur == 4 
    meetings = get_multi_day( roomid, s, enddate, duration )
  else
    meetings = get_recurring( roomid, recur, s, e )
  end

  if check_conflict( meetings, nil )
    halt 409,
      "Meeting is in conflict with another reservation."
  else

    if recur == 0 or recur == 1 or recur == 2 or recur == 4
      seriesid = Digest::MD5.hexdigest(user.to_s + meetings.to_s)[0,10].downcase
    else
      seriesid = ""
    end

    logger.info "this is the seriesid: #{seriesid}"

    Reservation.transaction do

      result = reserve( user.id, params[:title], params[:details],
        params[:recurring], meetings, seriesid )

      #add_invitees result, params[:invitees]

    end

    return ""

  end

end

post "/rest/authenticate" do

  token = authenticate( params[:email], params[:admin] )
  response.set_cookie( "booker", :value => token, :path => "/",
    :expires => Time.now + (60*60*24*30) )

end

delete "/rest/reservations/:reserveid" do

  user = check_token

  if params[:recurring].nil?
    halt 400, "Missing parameter recurring."
  else

    if params[:recurring] == "1"
      cancel_meeting( params[:reserveid].to_i, true )
    else
      cancel_meeting( params[:reserveid].to_i, false )
    end

  end

  return ""

end

put "/rest/reservations/:reserveid" do

  user = check_token

  reserveid = params[:reserveid].to_i
  recur     = params[:recurring].to_i
  roomid    = params[:roomid].to_i
  title     = params[:title]
  details   = params[:details]
  startdate = params[:start]
  enddate   = params[:end]
  time      = params[:time]
  duration  = params[:duration]

  s = get_date_time( startdate, time )

  if recur == 4

    x = get_date_time( enddate, time )
    e = add_date_time( x, duration )

  else
    e = add_date_time( s, duration )
  end

  if !check_date(s)                                                             
    halt 409,                                                                   
      "Cannot book meetings in the past."
  end

  reservations = get_reservations(reserveid)

  if reservations.nil?
    halt 404, "Reservation not found."
  else
                                                                                 
    old_recur    = reservations[0].recurring                                    
    old_start    = reservations[0].start                                        
    old_end      = reservations[0].end                                          
    old_seriesid = reservations[0].seriesid

  end

  if recur == old_recur

    if old_start == s and old_end == e

      Reservation.transaction do

        reservations.each do |r|

          r.room_id = roomid
          r.title   = title
          r.details = details

          if r.changed?
            r.save
          end

        end

      end

    else

      if recur == 4
        meetings = get_multi_day( roomid, s, enddate, duration )
      else
        meetings = get_recurring( roomid, recur, s, e )
      end

      if check_conflict( meetings, reserveid )
        halt 409,
          "Meeting is in conflict with another reservation."
      else
 
        Reservation.transaction do

           if recur == 4

             change_multi_day_reservations( reservations, roomid, title,
               details, old_recur, recur, meetings, old_seriesid )
 
           else

             modify_reservations( reserveid, roomid, title, details, recur,
               meetings, old_seriesid )

           end   

         end

      end

    end

  elsif (recur != old_recur) and (recur == 4 or old_recur == 4)
# multi-day handler
    logger.info "multi-day reservation modification"

    if recur == 4
      meetings = get_multi_day( roomid, s, enddate, duration )
    else
      meetings = get_recurring( roomid, recur, s, e )
    end

    if check_conflict( meetings, reserveid )
      halt 409,
        "Meeting is in conflict with another reservation."
    else

      Reservation.transaction do

        change_multi_day_reservations( reservations, roomid, title, details,
          old_recur, recur, meetings, old_seriesid )

      end

    end

  elsif recur > old_recur
# downgrade
    logger.info "downgrading reservation"

    Reservation.transaction do

      downgrade_reservations( reservations, old_recur, recur, roomid, title,
        details )

      if old_start != s or old_end != e

        meetings = get_recurring( roomid, recur, s, e )

        if check_conflict( meetings, reserveid )
          halt 409,
            "Meeting is in conflict with another reservation."
        else

          modify_reservations( reserveid, roomid, title, details, recur,
            meetings, old_seriesid )

        end

      end

    end

# upgrade 
  elsif recur < old_recur

    meetings = get_recurring( roomid, recur, s, e )

    if check_conflict( meetings, reserveid )
      halt 409,
        "Meeting is in conflict with another reservation."
    else

      Reservation.transaction do

        upgrade_reservations( reservations, meetings, old_recur, recur,
          roomid, title, details )

      end

    end


  end

  return ""

end

