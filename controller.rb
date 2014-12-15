require_relative 'statistica'

class Controller
  include Mongo
  # @param [Rack::Request] request
  # @param [Rack::Response] response
  def initialize(request, response)
    @req = request
    @res = response
  end

  def tutorial
    @res.write Statistica.new.tutorial + "\n"
  end
end