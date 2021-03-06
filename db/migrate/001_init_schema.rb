class InitSchema < ActiveRecord::Migration

  def self.up

    create_table :teams do |t|
      t.string :name
      t.timestamps
    end

    create_table :users do |t|
      t.belongs_to :team
      t.string :email, :null => false
      t.string :first
      t.string :last
      t.string :canonical
      t.string :icon, :default => 'glyphicons_003_user.png'
      t.boolean :admin, :default => false
      t.integer :karma, :default => 0
      t.timestamps
    end

    create_table :rooms do |t|
      t.string :name, :null => false
      t.string :chinese, :null => false
      t.integer :capacity
      t.text :description
      t.string :did
      t.string :extension
      t.integer :floor
      t.boolean :adminonly, :default => false
      t.timestamps
    end

    create_table :tags do |t|
      t.belongs_to :room
      t.string :tag, :null => false
      t.timestamps
    end

    create_table :roomtags do |t|
      t.integer :room_id
      t.integer :tag_id
    end

    create_table :reservations do |t|
      t.belongs_to :room
      t.belongs_to :user
      t.integer :room_id
      t.integer :user_id
      t.string :title
      t.text :details
      t.datetime :start
      t.datetime :end
      t.integer :recurring, :default => 0
      t.string :seriesid
      t.integer :originid
      t.timestamps
    end
      
    create_table :invitees do |t|
      t.belongs_to :reservation
      t.integer :user_id
      t.integer :reservation_id
    end

  end

  def self.down

    drop_table :teams

    drop_table :users

    drop_table :rooms

    drop_table :tags

    drop_table :roomtags

    drop_table :reservations

    drop_table :invitees

  end

end

