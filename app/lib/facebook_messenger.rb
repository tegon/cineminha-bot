require 'httparty'

class FacebookMessenger
  include HTTParty

  base_uri 'https://graph.facebook.com/v2.6/me/messages'
  headers 'Content-Type' => 'application/json'
  debug_output $stderr
  default_params 'access_token' => ENV['MESSENGER_ACCESS_TOKEN']

  def send(message_data)
    response = self.class.post(body: message_data)
    p 'send', response.response.body
  end
end
