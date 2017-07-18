if ENV['SSL'] == 'true'
  require 'rubygems'
  require 'rails/commands/server' 
  require 'rack' 
  require 'webrick' 
  require 'webrick/https'
  module Rails class Server < ::Rack::Server 
    def default_options
      super.merge({
        SSLEnable: true,
        SSLVerifyClient: OpenSSL::SSL::VERIFY_NONE,
        SSLPrivateKey: OpenSSL::PKey::RSA.new(
          File.open("/home/traveltriangle/.ssh/ssl/localhost.key").read
        ),
        SSLCertificate: OpenSSL::X509::Certificate.new(
          File.open("/home/traveltriangle/.ssh/ssl/localhost.crt").read
        ),
        SSLCertName: [["CN", WEBrick::Utils::getservername]], 
      })
    end
  end
end
end