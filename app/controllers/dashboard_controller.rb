class DashboardController < ApplicationController
  def index
    require 'net/http'
    require 'rubygems'
    require 'json'
      
    # settings
    host             = 'labs.evisions.com'
    port             = 80
    datablock        = 5995
    username         = 'webdemo'
    password         = 'webdemo'
    sessionParam     = "sessionid"
    setupSessionURI  = "/mw/Session.Setup?Version=4.2&JSONData={\"Mapplets\":[{\"Guid\":\"B052A35E-DC3B-4283-B732-7BEE3B095C5E\",\"Version\":\"4.2\"}]}"
    authenticateURI  = "/mw/Session.Authenticate?username=#{username}&password=#{password}&#{sessionParam}="
    securityTokenURI = "/mw/Session.SecurityToken.Create?#{sessionParam}="
    uri              = URI('https://'+host)
     
    def getData(siteURI, httpObject)
      request  = Net::HTTP::Get.new siteURI
      response = httpObject.request request  
      return JSON.parse response.body
    end
     
    Net::HTTP.start(uri.host, uri.port,
      use_ssl: uri.scheme == 'https',
      verify_mode: OpenSSL::SSL::VERIFY_NONE) do |http|
      
      # set up the session and retrieve the session id
      data = getData(setupSessionURI, http)
      if not data['valid']
        @flash = 'Could not setup session'
        exit
      end
     
      # Get the session and add it to the params of future requests
      session = data['data']['SessionId']
      if session.nil?
        @flash = 'You do not have the latest MAPS service'
        exit
      end
     
      authenticateURI  += session
      securityTokenURI += session
     
      # authenticate the session
      data = getData(authenticateURI, http)
      if not data['valid']
        @flash = 'Could not authenticate session'
        exit
      end
     
      # create the security token
      data = getData(securityTokenURI, http)   
      if not data['valid']
        @flash = 'Could not get token'
        exit
      end
     
      token = data['data']['Token']
      @url = "https://#{host}/Argos/AWV/#DataBlock=#{datablock}&Username=#{username}&Token=#{token}"
    end    
  end
end
