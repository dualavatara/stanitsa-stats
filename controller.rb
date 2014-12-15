require 'mongo'
require 'csv'
require_relative 'user'

class Controller
  include Mongo
  # @param [Rack::Request] request
  # @param [Rack::Response] response
  def initialize(request, response)
    @req = request
    @res = response

    # @type [Collection]
    @statistic = MongoClient.new("localhost", 27017).db("statistic").collection("statistic")
  end

  def tutorial
    tutcount = Hash.new 0

    @statistic.find("typeId" => "REGISTRATION").each do |row|
      user = User.new(@statistic, row)
      user.tutorials.each do |tutorialId, count|
        tutcount[tutorialId] += count
      end
    end

    csv_string = CSV.generate do |csv|
      csv << ["tutorialId", "count"]
      tutcount.sort.each do |pair|
        csv << pair
      end
    end

    @res.write csv_string + "\n"

  end
end