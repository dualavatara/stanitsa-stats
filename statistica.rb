require 'mongo'
require 'csv'
require_relative 'user'

class Statistica
  include Mongo

  def initialize
    # @type [Collection]
    @statistic = MongoClient.new("localhost", 27017).db("statistic").collection("statistic")
  end

  def tutorial
    tutcount = Hash.new 0

    cursor = @statistic.find("typeId" => "REGISTRATION")
    i = 0
    count = cursor.count
    cursor.each do |row|
      i += 1
      user = User.new(@statistic, row)
      user.tutorials.each do |tutorialId, count|
        tutcount[tutorialId] += count
      end
      puts "User #{i} of #{count} processed"
    end

    csv_string = CSV.generate do |csv|
      csv << ["tutorialId", "count"]
      tutcount.sort.each do |pair|
        csv << pair
      end
    end
  end
end