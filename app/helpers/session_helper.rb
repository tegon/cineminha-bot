module SessionHelper
  def store_command_in_session(message)
    p 'store_command_in_session', message.text
    p 'is_command', is_command?(message.text)
    p 'get', @session.get(message.from.id.to_s)
    @last_command = @session.get(message.from.id.to_s)[:last_command] if @session.get(message.from.id.to_s)
    @session.set(message.from.id.to_s, { last_command: message.text }) if is_command?(message.text)
  end
end