require 'mongo'

stat = MongoClient.new("localhost", 27017).db("statistic").collection("statistic")

#    sess = @statistic.find({"typeId" => "LOGIN", "appId" => 'stanitsa_ok_ru', 'ts' => {"$gt" => Time.now.to_i - 3600 * 24}}).count()
# sess = @statistic.find({"typeId" => "LOGIN", "appId" => 'stanitsa_ok_ru'}).count()
#    sess = @statistic.count({"typeId" => "LOGIN", "appId" => 'stanitsa_ok_ru', 'ts' => {"$gt" => Time.now.to_i - 3600 * 24}})
dayago = Time.at( Time.now.to_i - 3600 * 24)
puts dayago
# sess = @statistic.count({'ts' => {"$gt" => dayago.to_i}})
# puts sess
# puts @statistic.count("typeId" => "LOGIN", "appId" => 'stanitsa_vk_ru')
stat.create_index({'appId' => Mongo::ASCENDING, 'typeId' => Mongo::ASCENDING},{:background => true})
puts stat.index_information