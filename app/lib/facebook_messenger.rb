require 'httparty'

class FacebookMessenger
  include HTTParty

  base_uri 'https://graph.facebook.com/v2.6/me/messages'
  headers 'Content-Type' => 'application/json'
  debug_output $stderr
  default_params 'access_token' => ENV['MESSENGER_ACCESS_TOKEN']

  def self.send_message(recipient_id, message_data)
    response = post('/', body: {
      recipient: {
        id: recipient_id
      },
      message: message_data
    })
  end
end
