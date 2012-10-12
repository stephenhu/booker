class Reservation < ActiveRecord::Base

  belongs_to :rooms
  belongs_to :users
  has_many   :invitees, :dependent => :destroy

  def room_name

    r = Room.find(self.room_id)

    if r.nil?
      return nil
    else
      return r.combined_name
    end

  end

  def recurring_name

    recurring = [ "weekly", "bi-weekly", "monthly", "none", "multi-day" ]
    return recurring[self.recurring]    

  end

  def organizer_email

    u = User.find(self.user_id)

    if u.nil?
      return nil
    else
      return u.email
    end

  end

  def invitees_delimited

    delimited = ""

    self.invitees.each_with_index do |i, index|

      if index == 0
        delimited = i.email
      else
        delimited += ", "
        delimited += i.email
      end

    end

    return delimited

  end

end

