require "active_record"
require "active_record/fixtures"
require "digest/md5"
require "logger"
require "securerandom"
require "yaml"


task :default => :help

namespace :db do

  desc "establish connection"
  task :environment do

    @config = YAML.load_file('config/database.yml')['development']
    ActiveRecord::Base.establish_connection @config 
    ActiveRecord::Base.logger = Logger.new(STDOUT)

  end

  desc "create database"
  task :create => :environment do
    puts "this is an empty call, use migrate." 
  end

  desc "migrate database"
  task :migrate => :environment do

    ActiveRecord::Migration.verbose   = true
    ActiveRecord::Migrator.migrate("db/migrate")

  end

  desc "load seed fixtures from db/fixtures) into the db"
  task :seed => :environment do

    Dir.glob( 'db/fixtures/*.yml').each do |file|
      puts file
      ActiveRecord::Fixtures.create_fixtures( 'db/fixtures', File.basename( file, '.*' ) )
    end
  end
end

desc "generate help text"
task :help do

  puts "rake"
  puts "\tmigrate"
  puts "\tseed"

end

