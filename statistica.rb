require 'mongo'
require 'csv'
require_relative 'user'
require_relative 'event'

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

      user = User.new(@statistic, row)
      user.getAllEvents("TUTORIAL")
      # user.tutorials.each do |tutorialId, count|
      #   tutcount[tutorialId] += count
      # end

      # report progress
      i += 1
      puts "User #{i} of #{count} processed"
    end

    csv_string = CSV.generate do |csv|
      csv << ["tutorialId", "count"]
      tutcount.sort.each do |pair|
        csv << pair
      end
    end
  end

  def testevent
    reg = Event.new(@statistic, "typeId" => "REGISTRATION", "appId" => 'stanitsa_ok_ru', "data.platformId" => :platformId) do |result, row, count, total|
      result['count'] ||= 1
      # puts row.inspect
      # puts "Processed REGISTRATION #{count} of #{total}"
      result
    end

    login = Event.new(@statistic, "typeId" => "LOGIN", "appId" => 'stanitsa_ok_ru', "sessionId" => :sessionId) do |result, row, count, total|
      result['count'] = row['count'] ? row['count'] : 0

      # puts row.inspect
      # puts "Processed LOGIN #{count} of #{total}"
      # if total > 1
      #   result['stop'] = 1
      # end
      result
    end

    oldprc = 0

    tutorial = Event.new(@statistic, "typeId" => "TUTORIAL", "appId" => 'stanitsa_ok_ru') do |result, row, count, total|
      id = row['data']['tutorialId']
      c = row['count']
      if (!id.nil? && !c.nil?)
        result[id] = result[id] ? result[id] + c : c
      end

      # puts row.inspect
      # puts "Processed TUTORIAL #{count} of #{total}"
      # if row['stop']
      #   # exit(1)
      # end
      prc = (count * 100)/total
      if prc - oldprc > 1
        oldprc = prc
        puts "Processed TUTORIAL #{prc}%"
      end

      result
    end

    tutorial.bind(login.bind(reg))
    # reg.bind(login.bind(tutorial))
    # reg.bind(login)

    res = tutorial.query

    csv_string = CSV.generate do |csv|
      csv << ["tutorialId", "count"]
      res.sort.each do |pair|
        csv << pair
      end
    end
  end

end