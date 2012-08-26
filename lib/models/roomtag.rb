class RoomTag < ActiveRecord::Base
  belongs_to :rooms
  belongs_to :tags
end
