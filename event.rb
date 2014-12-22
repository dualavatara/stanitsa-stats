class Event
  attr_accessor :sort, :limit

  # def initialize(collection, row)
  #   @collection = collection
  #   row.to_a.each {|attr| self.send("#{attr[0]}=", attr[1])}
  # end
  def initialize(collection, selector = {}, &aggregator)
    @collection = collection
    @selector = selector
    @selectorOriginal = selector
    @aggregator = aggregator
  end

  def bind(event)
    @subevent = event
    self
  end

  def query
    result = Hash.new
    cursor = @collection.find(@selector)

    count = 0

    if @limit
      cursor.limit(@limit)
    end

    total = cursor.count()

    if @sort
      cursor.sort(@sort)
    end

    cursor.each do |row|
      count += 1

      if @subevent
        row.merge!(@subevent.prepare(row).query)
      end

      result = @aggregator.call(result, row, count, total)
    end

    result
  end

  def prepare(row)
    @selector = @selectorOriginal.dup
    @selector.each do |k, v|
      if v.is_a? Symbol
        if row[v.to_s]
          @selector[k] = row[v.to_s]
        elsif row['data'][v.to_s]
          @selector[k] = row['data'][v.to_s]
        end
      end
    end
    self
  end
end