class Reservation < ActiveRecord::Base

  belongs_to :rooms
  belongs_to :users
  has_many   :invitees, :dependent => :delete_all

  def room_name

    r = Room.find(self.room_id)

    if r.nil?
      return nil
    else
      return r.combined_name
    end

  end

  def recurring_name

    recurring = [ "none", "weekly", "bi-weekly", "monthly" ]
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

end

