require "digest/md5"
require "securerandom"

class User < ActiveRecord::Base

  has_many :reservations

  validates_uniqueness_of :email

  belongs_to :team

  before_create :set_salt
  before_create :set_uuid
  before_create :set_canonical

  def set_salt
    self.salt = SecureRandom.hex(8)
  end

  def set_canonical

    u = User.find_by_canonical(canonical_name)

    if u.nil?
      self.canonical = canonical_name
    else
      self.canonical = generate_canonical
    end

  end

  def set_uuid
    self.uuid = Digest::MD5.hexdigest(email + salt)
  end

  def canonical_name
    return email.split('@')[0]
  end

  def generate_canonical
    canonical_name + Digest::MD5.hexdigest(email)[0,2].downcase
  end

end

