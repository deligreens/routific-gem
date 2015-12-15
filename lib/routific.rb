require 'rest-client'
require 'json'

require_relative './routific/location'
require_relative './routific/visit'
require_relative './routific/vehicle'
require_relative './routific/route'
require_relative './routific/way_point'
require_relative './routific/job'

# Main class of this gem
class Routific
  Error           = Class.new(StandardError)
  InvalidEndpoint = Class.new(Error)

  ENDPOINTS = %i(vrp vrp-long pdp pdp-long)

  @@token    = nil
  @@endpoint = ENDPOINTS.first

  attr_reader :token, :visits, :fleet, :endpoint

  # Constructor
  # token: Access token for Routific API
  def initialize(token = @@token)
    @token = token
    @visits = {}
    @fleet = {}
    @endpoint = @@endpoint
  end

  def endpoint=(value)
    raise InvalidEndpoint unless ENDPOINTS.include?(value.to_sym)
    @endpoint = value
  end

  # Sets a visit for the specified location using the specified parameters
  # id: ID of location to visit
  # params: parameters for this visit
  def setVisit(id, params={})
    visits[id] = RoutificApi::Visit.new(id, params)
  end

  # Sets a vehicle with the specified ID and parameters
  # id: vehicle ID
  # params: parameters for this vehicle
  def setVehicle(id, params)
    fleet[id] = RoutificApi::Vehicle.new(id, params)
  end

  # Returns the route using the previously provided visits and fleet information
  def getRoute
    data = {
      visits: visits,
      fleet: fleet
    }

    Routific.getRoute(data, token, endpoint)
  end

  class << self
    # Sets the default access token to use
    def setToken(token)
      @@token = token
    end

    def token
      @@token
    end

    def endpoint
      @@endpoint
    end

    def endpoint=(value)
      raise InvalidEndpoint unless ENDPOINTS.include?(value.to_sym)
      @@endpoint = value
    end

    def getRoute(data, token = @@token, endpoint = @@endpoint)
      json = request path:   "v1/#{endpoint}",
                     method: :post,
                     data:   data.to_json,
                     token:  token
      if json
        if endpoint =~ /-long\z/
          RoutificApi::Job.new(id: json['job_id'])
        else
          RoutificApi::Route.parse(json)
        end
      end
    end

    def job(job_id, token = @@token)
      json = request path:   "jobs/#{job_id}",
                     method: :get,
                     token:  token
      if json
        RoutificApi::Job.parse(json)
      end
    end

    private

    def request(path:, method:, token:, data: nil)
      if token.nil?
        raise ArgumentError, 'Access token must be set.'
      end

      # Prefix the token with "bearer " if missing
      unless token =~ /\Abearer /
        token = "bearer #{token}"
      end

      unless %i(get post).include?(method.to_sym)
        raise ArgumentError, 'Only GET and POST methods are supported.'
      end

      args = {
        method: method,
        url:    "https://api.routific.com/#{path}",
        headers: {
          authorization: token,
          content_type:  :json,
          accept:        :json
        }
      }
      if method.to_sym == :post && data
        args[:payload] = data
      end

      begin
        response = RestClient::Request.execute args
      rescue => e
        puts e
        errorResponse = JSON.parse e.response.body
        puts "Received HTTP #{e.message}: #{errorResponse["error"]}"
        nil
      else
        JSON.parse(response)
      end
    end
  end
end
