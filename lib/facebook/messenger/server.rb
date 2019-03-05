require 'rack'
require 'json'
require 'openssl'
require 'net/http'
require 'uri'
require 'json'

module Facebook
  module Messenger
    class BadRequestError < Error; end

    X_HUB_SIGNATURE_MISSING_WARNING = <<-HEREDOC.freeze
      The X-Hub-Signature header is not present in the request. This is
      expected for the first webhook requests. If it continues after
      some time, check your app's secret token.
    HEREDOC

    #
    # This module holds the server that processes incoming messages from the
    # Facebook Messenger Platform.
    #
    class Server
	
      def self.call(env)
        new.call(env)
      end

      # Rack handler for request.
      def call(env)
	
        @request = Rack::Request.new(env)
        @response = Rack::Response.new

	

        if @request.get?
          verify
        elsif @request.post?
          receive
        else
          @response.status = 405
        end

        @response.finish
      end

      # @private
      private

      #
      # Function validates the verification request which is sent by Facebook
      #   to validate the entered endpoint.
      # @see https://developers.facebook.com/docs/graph-api/webhooks#callback
      #
      def verify
	
        if valid_verify_token?(@request.params['hub.verify_token'])
          @response.write @request.params['hub.challenge']
        else
          @response.write 'Error; wrong verify token'
        end
      end

      #
      # Function handles the webhook events.
      # @raise BadRequestError if the request is tampered.
      #
      def receive
        check_integrity
	
        trigger(parsed_body)
      rescue BadRequestError => error
        respond_with_error(error)
      end

      #
      # Check the integrity of the request.
      # @see https://developers.facebook.com/docs/messenger-platform/webhook#security
      #
      # @raise BadRequestError if the request has been tampered with.
      #
      def check_integrity
        # If app secret is not found in environment, return.
        # So for the security purpose always add provision in
        #   configuration provider to return app secret.

	  puts "********* TEST"
	puts parsed_body['entry'][0]

        return unless app_secret_for(parsed_body['entry'][0]['id'])

        unless signature.start_with?('sha1='.freeze)
          warn X_HUB_SIGNATURE_MISSING_WARNING

          raise BadRequestError, 'Error getting integrity signature'.freeze
        end

        raise BadRequestError, 'Error checking message integrity'.freeze \
          unless valid_signature?
      end

      # Returns a String describing the X-Hub-Signature header.
      def signature
        @request.env['HTTP_X_HUB_SIGNATURE'.freeze].to_s
      end

      #
      # Verify that the signature given in the X-Hub-Signature header matches
      # that of the body.
      #
      # @return [Boolean] true if request is valid else false.
      #
      def valid_signature?
        Rack::Utils.secure_compare(signature, signature_for(body))
      end

      #
      # Sign the given string.
      #
      # @return [String] A string describing its signature.
      #
      def signature_for(string)
        format('sha1=%<string>s'.freeze, string: generate_hmac(string))
      end

      # Generate a HMAC signature for the given content.
      def generate_hmac(content)
        content_json = JSON.parse(content, symbolize_names: true)
        facebook_page_id = content_json[:entry][0][:id]

        OpenSSL::HMAC.hexdigest('sha1'.freeze,
                                app_secret_for(facebook_page_id),
                                content)
      end

      # Returns a String describing the bot's configured app secret.
      def app_secret_for(facebook_page_id)
        Facebook::Messenger.config.provider.app_secret_for(facebook_page_id)
      end

      # Checks whether a verify token is valid.
      def valid_verify_token?(token)
        Facebook::Messenger.config.provider.valid_verify_token?(token)
      end

      # Returns a String describing the request body.
      def body
        @body ||= @request.body.read
      end

      #
      # Returns a Hash describing the parsed request body.
      # @raise JSON::ParserError if body hash is not valid.
      #
      # @return [JSON] Parsed body hash.
      #
      def parsed_body
        @parsed_body ||= JSON.parse(body)
      rescue JSON::ParserError
        raise BadRequestError, 'Error parsing request body format'
      end

      #
      # Function hand over the webhook event to handlers.
      #
      # @param [Hash] events Parsed body hash in webhook event.
      #
     
      def trigger(events)
        # Facebook may batch several items in the 'entry' array during
        # periods of high load.
	      
	      		
	      
        events['entry'.freeze].each do |entry|
          # If the application has subscribed to webhooks other than Messenger,
          # 'messaging' won't be available and it is not relevant to us.
		
		
	  # WHEN PAGE ADMIN DONE CHATING WITH USER AND CLICK TO DONE BUTTON
	  messaging =  entry['messaging']

	  unless defined?(messaging[0]['pass_thread_control']).nil?
		  pass_thread_control = messaging[0]['pass_thread_control']
		  unless defined?(pass_thread_control['new_owner_app_id']).nil?
		  	puts pass_thread_control['new_owner_app_id']
		 	if pass_thread_control['new_owner_app_id'].to_s == Settings.owner_app_id.to_s
				puts "PASS THREAD CONTROL"
				sender = messaging[0]['sender']
				sender_id = sender['id']
				puts sender_id
				@data = []
			        file = IniFile.load(Rails.root.join('app/assets/config_agent_live.ini'))
            			data = file["agent live"]
				Bot.deliver({recipient: {id: sender_id},
                    			message: {text: "#{data['messageRelaisBot']}"},
                    			message_type: "RESPONSE"},
                    			access_token: Settings.facebook_accesss_token)
				Contact.where(:facebook_id => sender_id).update(handover_reset: '')
		  	end
		  end  
	  end
	  
	unless entry['messaging'.freeze]
		


		#standby = entry['standby']
		#puts standby[0]['sender']['id']
		#unless standby[0]['delivery'].nil?
		#	sender_id = standby[0]['sender']['id']
		#	agent = Contact.find_by(:facebook_id => sender_id).agent
		#	Contact.where(:facebook_id => sender_id).update(handover_reset: '')
		#end
	end
	  
		
          next unless entry['messaging'.freeze]
          # Facebook may batch several items in the 'messaging' array during
          # periods of high load.
		
          entry['messaging'.freeze].each do |messaging|
		#puts "******* GET THREAD OWNER"
                #uri = URI.parse("https://graph.facebook.com/v2.6/me/thread_owner?recipient=2059758140732393&access_token=#{Settings.facebook_accesss_token}")
                #response = Net::HTTP.get(uri)
                #response = JSON.parse(response)
                #current_app_id = response["data"][0]["thread_owner"]["app_id"]
		#  puts current_app_id
		#  puts Settings.owner_app_id
		#if current_app_id.to_s == Settings.owner_app_id.to_s
	    	 Facebook::Messenger::Bot.receive(messaging)

		#else
		 # SET USER TO 'CHAT WITH AN AGENT' STATE
	  	
		  
		#end
          end
        end
	      
	      
      end

      #
      # If received request is tampered, sent 400 code in response.
      #
      # @param [Object] error Error object.
      #
      def respond_with_error(error)
        @response.status = 400
        @response.write(error.message)
        @response.headers['Content-Type'.freeze] = 'text/plain'.freeze
      end
    end
  end
end
