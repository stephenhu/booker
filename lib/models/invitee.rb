class Invitee < ActiveRecord::Base

  belongs_to :reservations

  def email

    u = User.find(self.user_id)

    if !u.nil?
      return u.email
    else
      return nil
    end

  end

end
