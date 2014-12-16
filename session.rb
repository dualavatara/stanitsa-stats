class Session
  attr_reader :sid

  def initialize(collection, session)
    @col = collection
    @sid = session["sessionId"]
  end

  def tutorials
    tutcount = Hash.new 0
    @col.find("typeId" => "TUTORIAL", "sessionId" => @sid).each do |row|
      tutcount[row["data"]["tutorialId"]] = 1
    end
    tutcount
  end


end