require_relative 'session'

class User

  def initialize(collection, user)
    @col = collection
    @platform_id = user['data']['platformId']
  end

  def tutorials
    tutcount = Hash.new 0
    @col.find("typeId" => "LOGIN", "data.platformId" => @platform_id).each do |row|
      session = Session.new(@col, row)
      session.tutorials.each do |tutorialId, count|
        tutcount[tutorialId] = count
      end
    end
    tutcount
  end

  def getAllEvents(typeId)
    @col.find("typeId" => "LOGIN", "data.platformId" => @platform_id).each do |row|
      sid = row["sessionId"]

      @col.find("typeId" => typeId, "sessionId" => sid).each do |row|

      end
    end
  end
end