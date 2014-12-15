require 'rack'
require 'rack/response'
require_relative 'controller'

class Dispatcher
  def self.call(env)
    request = Rack::Request.new env
    response = Rack::Response.new

    controller = Controller.new(request, response)
    if (request[:action] and controller.respond_to? request[:action])
      controller.send request[:action]
    end

    response.status = 200
    response.finish
  end
end