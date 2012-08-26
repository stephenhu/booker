class Tag < ActiveRecord::Base

  has_and_belongs_to_many :rooms, :join_table => "roomtags"

  validates_uniqueness_of :tag

end
