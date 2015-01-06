require 'mongo'
require 'csv'
require_relative 'event'

class Statistica
  include Mongo

  def initialize
    # @type [Collection]
    @statistic = MongoClient.new("localhost", 27017).db("statistic").collection("statistic")
  end

  def tutorial
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

  def levels
    oldprc = 0

    level = Event.new(@statistic, "typeId" => "GET_LEVEL", "appId" => 'stanitsa_ok_ru') do |result, row, count, total|
      l = row['data']['expLevel']
      c = row['count']
      a = row['age']
      if (!l.nil? && !c.nil?)
        unless result[l]
          result.store(l, {'count_events' => 0, 'avg_away_time' => 0, 'last_user' => ''})
        end
        result[l]['count_events'] = result[l]['count_events'] ?  result[l]['count_events'] + c : c
        result[l]['avg_away_time'] = result[l]['avg_away_time'] ?  (result[l]['avg_away_time'] + a)/2 : a
        result[l]['last_user'] = row['last_user']
      end

      if c == 0
        puts row.inspect
      end

      prc = (count * 100)/total
      if prc - oldprc > 1
        oldprc = prc
        puts "Processed GET_LEVEL #{prc}%"
      end

      result
    end

    login = Event.new(@statistic, "typeId" => "LOGIN", "appId" => 'stanitsa_ok_ru', "sessionId" => :sessionId) do |result, row, count, total|
      result['count'] ||= 1
      result['age'] ||= row['age']
      result['last_user'] ||= row['data']['platformId']
      result
    end

    last = Event.new(@statistic, "appId" => 'stanitsa_ok_ru', "sessionId" => :sessionId) do |result, row, count, total|
      result['age'] ||= Time.now.to_i - row['ts'] > 0 ? Time.now.to_i - row['ts'] : 0
      result
    end

    last.limit = 1
    last.sort = {:ts => :desc}

    level.bind(login.bind(last))

    res = level.query

    csv_string = CSV.generate do |csv|
      csv << ["level", "count_events", "avg_away_time", 'last_user']
      res.sort.each do |pair|
        csv << [pair[0], pair[1]['count_events'], pair[1]['avg_away_time'], pair[1]['last_user']]
      end
    end

  end

  def test
    l3 = @statistic.find("typeId" => "GET_LEVEL", "appId" => 'stanitsa_ok_ru', 'data.expLevel' => 3).count()
    l4 = @statistic.find("typeId" => "GET_LEVEL", "appId" => 'stanitsa_ok_ru', 'data.expLevel' => 4).count()
    l5 = @statistic.find("typeId" => "GET_LEVEL", "appId" => 'stanitsa_ok_ru', 'data.expLevel' => 5).count()
    puts l3
    puts l4
    puts l5
  end

  def quest
    oldprc = 0
    questsStart = Event.new(@statistic, "appId" => 'stanitsa_ok_ru', "typeId" => "GET_QUEST") do |result, row, count, total|
      result[row['data']['questId']] ||= 0
      result[row['data']['questId']] += 1

      prc = (count * 100)/total
      if prc - oldprc > 1
        oldprc = prc
        puts "Processed GET_QUEST #{prc}%"
      end

      result
    end



    questsEnd = Event.new(@statistic, "appId" => 'stanitsa_ok_ru', "typeId" => "END_QUEST") do |result, row, count, total|
      result[row['data']['questId']] ||= 0
      result[row['data']['questId']] += 1

      prc = (count * 100)/total
      if prc - oldprc > 1
        oldprc = prc
        puts "Processed END_QUEST #{prc}%"
      end

      result
    end

    # questsEnd.limit = 10
    # questsStart.limit = 10

    resStart = questsStart.query
    oldprc = 0
    resEnd = questsEnd.query

    res = Hash.new
    resStart.each do |questId, numStarted|
      numEnded = resEnd[questId] ? resEnd[questId] : 0
      res[questId] = [numStarted, numEnded]
    end

    csv_string = CSV.generate do |csv|
      csv << ["questId", "num_started", "num_ended"]
      res.sort.each do |pair|
        csv << [pair[0], pair[1][0], pair[1][1]]
      end
    end
  end

  def sessions
    sess = @statistic.find("typeId" => "LOGIN", "appId" => 'stanitsa_ok_ru', 'ts' => {"$gt" => Time.now.to_i - 3600 * 24}).count()
    puts sess
  end
end