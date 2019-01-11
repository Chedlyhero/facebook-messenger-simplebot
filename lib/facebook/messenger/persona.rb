require 'httparty'

module Facebook
  module Messenger
    module Persona
      include HTTParty

      base_uri 'https://graph.facebook.com/v3.2/me'

      format :json

      module_function

      def create_persona(settings, access_token:)
        response = post '/personas', body: settings, query: {
          access_token: access_token
        }
        
        puts "Persona ///////////////"
        puts response.id
        FacebookMessengerService.setPersonaId(response.id)
        
        raise_errors(response)

        true
      end

      def raise_errors(response)
        raise Error, response['error'] if response.key? 'error'
      end

      class Error < Facebook::Messenger::FacebookError; end
    end
  end
end
