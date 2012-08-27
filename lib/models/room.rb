class Room < ActiveRecord::Base

  has_and_belongs_to_many :tags, :join_table => "roomtags"

  def combined_name
    return name + "/" + chinese
  end

  def descriptive_name
    return combined_name + "/(capacity #{capacity})"
  end

  def full_name
    return descriptive_name + "/(floor #{floor})"
  end

end
