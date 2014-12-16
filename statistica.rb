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
          result.store(l, {'count_users' => 0, 'avg_away_time' => 0})
        end
        result[l]['count_users'] = result[l]['count_users'] ?  result[l]['count_users'] + c : c
        result[l]['avg_away_time'] = result[l]['avg_away_time'] ?  (result[l]['avg_away_time'] + a)/2 : a
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
      result
    end

    last = Event.new(@statistic, "appId" => 'stanitsa_ok_ru', "sessionId" => :sessionId) do |result, row, count, total|
      result['age'] ||= Time.now.to_i - row['ts'] > 0 ? Time.now.to_i - row['ts'] : 0
      result
    end

    last.limit = 1
    last.sort = {:ts => :desc}

    level.limit=10
    level.bind(login.bind(last))

    res = level.query

    csv_string = CSV.generate do |csv|
      csv << ["level", "count_users", "avg_away_time"]
      res.sort.each do |pair|
        csv << [pair[0], pair[1]['count_users'], pair[1]['avg_away_time']]
      end
    end

  end

end