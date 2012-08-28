class Reservation < ActiveRecord::Base
  belongs_to :rooms
  belongs_to :users
end
